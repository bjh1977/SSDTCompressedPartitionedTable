CREATE PROCEDURE [dbo].[spMaintainPartitionTableCompression]
	@PartitionTableName NVARCHAR(510)
AS
	
BEGIN

	DECLARE @PartitionNumber INT;
	DECLARE @SQL NVARCHAR(1000);

	SET @PartitionNumber = (select top 1 partition_number from sys.partitions p WHERE p.object_id = OBJECT_ID(@PartitionTableName) AND p.data_compression_desc <> 'PAGE' ORDER BY p.partition_number)

	WHILE @PartitionNumber IS NOT NULL
	BEGIN
		PRINT 'Rebuilding partition number ' + CAST(@PartitionNumber AS NVARCHAR(10)) + ' with DATA_COMPRESSION = PAGE';

		SET @SQL =	'ALTER TABLE ' + @PartitionTableName + ' REBUILD PARTITION = ' + CAST(@PartitionNumber AS NVARCHAR(10)) + ' WITH (DATA_COMPRESSION = PAGE)';

		EXEC sp_executesql @SQL;			

		SET @PartitionNumber = (select top 1 partition_number from sys.partitions p WHERE p.object_id = OBJECT_ID(@PartitionTableName) AND p.data_compression_desc <> 'PAGE' AND p.partition_number > @PartitionNumber ORDER BY p.partition_number)

	END
END