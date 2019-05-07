--
-- DROP TABLE, PARTITION SCHEMA, PARTITION FUNCTION
--
IF EXISTS (select * FROM sys.tables t WHERE name = 'IntegerPartitionedTable')
BEGIN
	DROP TABLE [IntegerPartitionedTable]
END

IF EXISTS (select * FROM sys.partition_schemes ps WHERE name = 'IntegerPScheme')
BEGIN
	DROP PARTITION SCHEME [IntegerPScheme]
END

IF EXISTS (select * FROM sys.partition_functions pf WHERE name = 'IntegerPFN')
BEGIN
	DROP PARTITION FUNCTION [IntegerPFN]
END

GO




--
-- CREATE PARTITION FUNCTION
--
CREATE PARTITION FUNCTION [IntegerPFN](INT)
    AS RANGE
    FOR VALUES (10, 20);
GO

--
-- CREATE PARTITION SCHEME
--
CREATE PARTITION SCHEME [IntegerPScheme]
    AS PARTITION [IntegerPFN]
    ALL TO ([PRIMARY]);
GO

--
-- CREATE PARTITIONED TABLE (COMPRESSION NOT SPECIFIED)
--
CREATE TABLE [dbo].[IntegerPartitionedTable] (
    [ID]           INT           NOT NULL,
    [PartitionKey] INT           NOT NULL,
    [ColA]         VARCHAR (100) NULL,
    [ColB]         VARCHAR (100) NULL
) ON [IntegerPScheme] ([PartitionKey]);
GO


--
-- INSPECT PARTITIONS (COMPRESSION = NONE)
--
SELECT OBJECT_NAME(p.object_id) AS ObjectName ,
 i.name AS IndexName ,
 p.index_id AS IndexID ,
 ds.name AS PartitionScheme ,
 p.partition_number AS PartitionNumber ,
 fg.name AS FileGroupName ,
 prv_left.value AS LowerBoundaryValue ,
 prv_right.value AS UpperBoundaryValue ,
 CASE pf.boundary_value_on_right
 WHEN 1 THEN 'RIGHT'
 ELSE 'LEFT'
 END AS PartitionFunctionRange ,
 p.rows AS Rows,
 data_compression_desc
FROM sys.partitions AS p
 INNER JOIN sys.indexes AS i ON i.object_id = p.object_id
 AND i.index_id = p.index_id
 INNER JOIN sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id
 INNER JOIN sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id
 INNER JOIN sys.partition_functions AS pf ON pf.function_id = ps.function_id
 INNER JOIN sys.destination_data_spaces AS dds ON dds.partition_scheme_id = ps.data_space_id
 AND dds.destination_id = p.partition_number
 INNER JOIN sys.filegroups AS fg ON fg.data_space_id = dds.data_space_id
 LEFT OUTER JOIN sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id
 AND prv_left.boundary_id = p.partition_number- 1
 LEFT OUTER JOIN sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id
 AND prv_right.boundary_id = p.partition_number
WHERE p.object_id = OBJECT_ID('IntegerPartitionedTable');


-- SPLIT PARTITION
ALTER PARTITION SCHEME [IntegerPScheme] 
NEXT USED [PRIMARY] 
ALTER PARTITION FUNCTION [IntegerPFN]() SPLIT RANGE(30)



--
-- INSPECT PARTITIONS AGAIN (DATA COMPRESSION STILL = NONE)
--
SELECT OBJECT_NAME(p.object_id) AS ObjectName ,
 i.name AS IndexName ,
 p.index_id AS IndexID ,
 ds.name AS PartitionScheme ,
 p.partition_number AS PartitionNumber ,
 fg.name AS FileGroupName ,
 prv_left.value AS LowerBoundaryValue ,
 prv_right.value AS UpperBoundaryValue ,
 CASE pf.boundary_value_on_right
 WHEN 1 THEN 'RIGHT'
 ELSE 'LEFT'
 END AS PartitionFunctionRange ,
 p.rows AS Rows,
 p.data_compression_desc
FROM sys.partitions AS p
 INNER JOIN sys.indexes AS i ON i.object_id = p.object_id
 AND i.index_id = p.index_id
 INNER JOIN sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id
 INNER JOIN sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id
 INNER JOIN sys.partition_functions AS pf ON pf.function_id = ps.function_id
 INNER JOIN sys.destination_data_spaces AS dds ON dds.partition_scheme_id = ps.data_space_id
 AND dds.destination_id = p.partition_number
 INNER JOIN sys.filegroups AS fg ON fg.data_space_id = dds.data_space_id
 LEFT OUTER JOIN sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id
 AND prv_left.boundary_id = p.partition_number- 1
 LEFT OUTER JOIN sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id
 AND prv_right.boundary_id = p.partition_number
WHERE p.object_id = OBJECT_ID('IntegerPartitionedTable');

GO


--
-- REBUILD ALL PARTIONS WHERE DATA_COMPRESSION <> 'PAGE
-- (to be used in a post deploy script?)
--

CREATE OR ALTER PROCEDURE [dbo].[spMaintainPartitionTableCompression]
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
GO

EXEC spMaintainPartitionTableCompression 'IntegerPartitionedTable'



--
-- INSPECT PARTITIONS AGAIN (DATA COMPRESSION NOW = PAGE)
--
SELECT OBJECT_NAME(p.object_id) AS ObjectName ,
 i.name AS IndexName ,
 p.index_id AS IndexID ,
 ds.name AS PartitionScheme ,
 p.partition_number AS PartitionNumber ,
 fg.name AS FileGroupName ,
 prv_left.value AS LowerBoundaryValue ,
 prv_right.value AS UpperBoundaryValue ,
 CASE pf.boundary_value_on_right
 WHEN 1 THEN 'RIGHT'
 ELSE 'LEFT'
 END AS PartitionFunctionRange ,
 p.rows AS Rows,
 data_compression_desc
FROM sys.partitions AS p
 INNER JOIN sys.indexes AS i ON i.object_id = p.object_id
 AND i.index_id = p.index_id
 INNER JOIN sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id
 INNER JOIN sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id
 INNER JOIN sys.partition_functions AS pf ON pf.function_id = ps.function_id
 INNER JOIN sys.destination_data_spaces AS dds ON dds.partition_scheme_id = ps.data_space_id
 AND dds.destination_id = p.partition_number
 INNER JOIN sys.filegroups AS fg ON fg.data_space_id = dds.data_space_id
 LEFT OUTER JOIN sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id
 AND prv_left.boundary_id = p.partition_number- 1
 LEFT OUTER JOIN sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id
 AND prv_right.boundary_id = p.partition_number
WHERE p.object_id = OBJECT_ID('IntegerPartitionedTable');


-- SPLIT PARTITION AGAIN
ALTER PARTITION SCHEME [IntegerPScheme] 
NEXT USED [PRIMARY] 
ALTER PARTITION FUNCTION [IntegerPFN]() SPLIT RANGE(50)


--
-- INSPECT PARTITIONS AGAIN (NEW PARTITION DATA COMPRESSION STILL = PAGE)
--
SELECT OBJECT_NAME(p.object_id) AS ObjectName ,
 i.name AS IndexName ,
 p.index_id AS IndexID ,
 ds.name AS PartitionScheme ,
 p.partition_number AS PartitionNumber ,
 fg.name AS FileGroupName ,
 prv_left.value AS LowerBoundaryValue ,
 prv_right.value AS UpperBoundaryValue ,
 CASE pf.boundary_value_on_right
 WHEN 1 THEN 'RIGHT'
 ELSE 'LEFT'
 END AS PartitionFunctionRange ,
 p.rows AS Rows,
 data_compression_desc
FROM sys.partitions AS p
 INNER JOIN sys.indexes AS i ON i.object_id = p.object_id
 AND i.index_id = p.index_id
 INNER JOIN sys.data_spaces AS ds ON ds.data_space_id = i.data_space_id
 INNER JOIN sys.partition_schemes AS ps ON ps.data_space_id = ds.data_space_id
 INNER JOIN sys.partition_functions AS pf ON pf.function_id = ps.function_id
 INNER JOIN sys.destination_data_spaces AS dds ON dds.partition_scheme_id = ps.data_space_id
 AND dds.destination_id = p.partition_number
 INNER JOIN sys.filegroups AS fg ON fg.data_space_id = dds.data_space_id
 LEFT OUTER JOIN sys.partition_range_values AS prv_left ON ps.function_id = prv_left.function_id
 AND prv_left.boundary_id = p.partition_number- 1
 LEFT OUTER JOIN sys.partition_range_values AS prv_right ON ps.function_id = prv_right.function_id
 AND prv_right.boundary_id = p.partition_number
WHERE p.object_id = OBJECT_ID('IntegerPartitionedTable');

