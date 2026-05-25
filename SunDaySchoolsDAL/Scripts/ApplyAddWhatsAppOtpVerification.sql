-- Run once if EF migration 20260525120000_AddWhatsAppOtpVerification was not applied.
IF COL_LENGTH('AspNetUsers', 'IsPhoneVerified') IS NULL
BEGIN
    ALTER TABLE [AspNetUsers] ADD [IsPhoneVerified] bit NOT NULL CONSTRAINT [DF_AspNetUsers_IsPhoneVerified] DEFAULT (1);
END
GO

IF OBJECT_ID(N'[OtpVerifications]', N'U') IS NULL
BEGIN
    CREATE TABLE [OtpVerifications] (
        [Id] int NOT NULL IDENTITY,
        [PhoneNumber] nvarchar(32) NOT NULL,
        [Code] nvarchar(128) NOT NULL,
        [ExpirationTime] datetime2 NOT NULL,
        [IsUsed] bit NOT NULL,
        [Purpose] int NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        [FailedAttempts] int NOT NULL,
        CONSTRAINT [PK_OtpVerifications] PRIMARY KEY ([Id])
    );

    CREATE INDEX [IX_OtpVerifications_PhoneNumber_Purpose_CreatedAt]
        ON [OtpVerifications] ([PhoneNumber], [Purpose], [CreatedAt]);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260525120000_AddWhatsAppOtpVerification'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260525120000_AddWhatsAppOtpVerification', N'8.0.0');
END
GO
