using System.Data.Common;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;
using Church.DAL.Repository.Interfaces;
using Church.DAL.DBcontext;

public class UnitOfWork : IUnitOfWork
{
    private readonly ProgramContext _context;
    private readonly ILogger<UnitOfWork> _logger;
    private IDbContextTransaction? _transaction;

    public UnitOfWork(ProgramContext context, ILogger<UnitOfWork> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task BeginTransactionAsync()
    {
        await ClearTransactionAsync();

        _transaction = await _context.Database.BeginTransactionAsync();
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }

    public async Task CommitAsync()
    {
        if (_transaction == null)
            return;

        var transaction = _transaction;
        _transaction = null;

        try
        {
            await transaction.CommitAsync();
        }
        finally
        {
            await DisposeTransactionSafeAsync(transaction);
        }
    }

    public async Task RollbackAsync()
    {
        if (_transaction == null)
            return;

        var transaction = _transaction;
        _transaction = null;

        if (IsTransactionUsable(transaction))
        {
            try
            {
                await transaction.RollbackAsync();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Transaction rollback failed; the transaction may already be completed or disposed.");
            }
        }

        await DisposeTransactionSafeAsync(transaction);
    }

    private async Task ClearTransactionAsync()
    {
        if (_transaction == null)
            return;

        var transaction = _transaction;
        _transaction = null;

        if (IsTransactionUsable(transaction))
        {
            try
            {
                await transaction.RollbackAsync();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Failed to roll back a previous transaction before starting a new one.");
            }
        }

        await DisposeTransactionSafeAsync(transaction);
    }

    private static bool IsTransactionUsable(IDbContextTransaction transaction)
    {
        try
        {
            if (transaction is not IInfrastructure<DbTransaction> infrastructure)
                return true;

            var dbTransaction = infrastructure.Instance;
            var connection = dbTransaction.Connection;
            if (connection == null)
                return false;

            return connection.State == System.Data.ConnectionState.Open;
        }
        catch
        {
            return false;
        }
    }

    private async Task DisposeTransactionSafeAsync(IDbContextTransaction transaction)
    {
        try
        {
            await transaction.DisposeAsync();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to dispose database transaction.");
        }
    }
}
