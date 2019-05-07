CREATE TABLE [dbo].[IntegerPartitionedTable] (
    [ID]        INT           NOT NULL,
    [PartitionKey] INT           NOT NULL,
    [ColA]      VARCHAR (100) NULL,
    [ColB]      VARCHAR (100) NULL
) ON [IntegerPScheme] (PartitionKey);


GO

