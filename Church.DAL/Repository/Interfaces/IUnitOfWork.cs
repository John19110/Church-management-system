using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.DAL.Repository.Interfaces
{
    public interface IUnitOfWork
    {
        /// <summary>
        /// Runs <paramref name="operation"/> inside a SQL transaction that is compatible
        /// with <c>EnableRetryOnFailure</c> (via <c>CreateExecutionStrategy</c>).
        /// Prefer this over <see cref="BeginTransactionAsync"/> / Commit / Rollback.
        /// </summary>
        Task ExecuteInTransactionAsync(Func<Task> operation);

        Task BeginTransactionAsync();
        Task CommitAsync();
        Task RollbackAsync();
        Task SaveChangesAsync();
    }
}
