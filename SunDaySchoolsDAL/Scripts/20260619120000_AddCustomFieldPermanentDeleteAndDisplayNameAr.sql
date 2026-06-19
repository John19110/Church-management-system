-- Custom field definition columns (DisplayNameAr, IsPermanentlyDeleted)
-- Run in hosting SQL panel if API startup repair has not run yet.

IF COL_LENGTH('CustomFieldDefinitions', 'DisplayNameAr') IS NULL
BEGIN
    ALTER TABLE [CustomFieldDefinitions] ADD [DisplayNameAr] nvarchar(256) NULL;
END
GO

IF COL_LENGTH('CustomFieldDefinitions', 'IsPermanentlyDeleted') IS NULL
BEGIN
    ALTER TABLE [CustomFieldDefinitions] ADD [IsPermanentlyDeleted] bit NOT NULL
        CONSTRAINT [DF_CustomFieldDefinitions_IsPermanentlyDeleted] DEFAULT(0);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260619120000_AddCustomFieldPermanentDeleteAndDisplayNameAr')
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260619120000_AddCustomFieldPermanentDeleteAndDisplayNameAr', N'8.0.0');
END
GO
