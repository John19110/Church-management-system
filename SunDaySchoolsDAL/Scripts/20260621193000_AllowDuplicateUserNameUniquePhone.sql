-- Allow duplicate usernames; enforce unique phone numbers on AspNetUsers.
-- Idempotent: safe to run on environments where EF migration history is incomplete.

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UserNameIndex'
      AND object_id = OBJECT_ID(N'AspNetUsers')
      AND is_unique = 1)
BEGIN
    DROP INDEX [UserNameIndex] ON [AspNetUsers];
END
GO

IF COL_LENGTH(N'AspNetUsers', N'PhoneNumber') IS NOT NULL
BEGIN
    ALTER TABLE [AspNetUsers] ALTER COLUMN [PhoneNumber] nvarchar(32) NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'UserNameIndex'
      AND object_id = OBJECT_ID(N'AspNetUsers'))
BEGIN
    CREATE INDEX [UserNameIndex] ON [AspNetUsers]([NormalizedUserName])
    WHERE [NormalizedUserName] IS NOT NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_AspNetUsers_PhoneNumber'
      AND object_id = OBJECT_ID(N'AspNetUsers'))
BEGIN
    CREATE UNIQUE INDEX [IX_AspNetUsers_PhoneNumber] ON [AspNetUsers]([PhoneNumber])
    WHERE [PhoneNumber] IS NOT NULL AND [PhoneNumber] <> '';
END
GO
