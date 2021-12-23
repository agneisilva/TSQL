 CREATE procedure [dbo].[Script_indice_sps]       
  @TableName Nvarchar(2000)      
  as      
 /***************************************first parts creates table*************************/        
 DECLARE     @idxTableName SYSNAME,        
                     @idxTableID INT,        
                     @idxname SYSNAME,        
                     @idxid INT,        
                     @colCount INT,        
                     @colCountMinusIncludedColumns INT,        
                     @IxColumn SYSNAME,        
                     @IxFirstColumn BIT,        
                     @ColumnIDInTable INT,        
                     @ColumnIDInIndex INT,        
                     @IsIncludedColumn INT,        
                     @sIncludeCols VARCHAR(MAX),        
                     @sIndexCols VARCHAR(MAX),        
                     @sSQL VARCHAR(MAX),        
                     @sParamSQL VARCHAR(MAX),        
                     @sFilterSQL VARCHAR(MAX),        
                     @location SYSNAME,        
                     @IndexCount INT,        
                     @CurrentIndex INT,        
                     @CurrentCol INT,        
                     @Name VARCHAR(128),        
                     @IsPrimaryKey TINYINT,        
                     @Fillfactor INT,        
                     @FilterDefinition VARCHAR(MAX),        
                     @IsClustered BIT         
 /***************************************set table name here******************************************/        
        
        
   IF(OBJECT_ID('tempdb..#Text')) IS NOT NULL        
           DROP TABLE #Text        
 CREATE TABLE #TEXT        
 (        
       nome varchar(500), Source NVarchar(4000)        
 )        
       
 INSERT INTO #Text(nome, Source)        
 Select        
       ind.name, 'alter table ' + @TableName + ' add Constraint [' + ind.name + '] ' + case when xtype='PK' Then ' Primary Key ' Else ' Unique ' End + Case when ind.status & 16=16 Then ' clustered ' Else ' nonclustered'     
       End + '(' + dbo.GetAllIndexedColumns(@TableName, 2) + ')'        
 From        
       sysindexes ind Join sysobjects tbl On tbl.parent_obj = object_id(@TableName)        
             and ind.name = object_name(tbl.id)        
             and xtype in ('UQ')        
 Insert Into #Text(nome, Source)        
 select        
       tbl.name,  'alter table ' + @TableName + ' add Constraint [' + tbl.name + '] FOREIGN KEY ([' + col_name(fk.fkeyid, fk.fkey) + ']) REFERENCES [' +         
       object_name(fk.rkeyid) + ']([' + col_name(fk.rkeyid, fk.rkey) + '])'        
 from          
       sysforeignkeys fk Join sysobjects tbl On tbl.parent_obj = object_id(@TableName)        
                   and fk.constid = tbl.id        
                   and xtype in ('F')        
 Declare @Source as Nvarchar(4000);        
 Select @Source = Source From #Text;        
      
 /***************************************first parts creates table index scripts uncomments the declares if used seperatly*************************/        
 --DECLARE    @TableName Nvarchar(2000),        
 --@idxTableName SYSNAME,        
 --@idxTableID INT,        
 --@idxname SYSNAME,        
 --@idxid INT,        
 --@colCount INT,        
 --@colCountMinusIncludedColumns INT,        
 --@IxColumn SYSNAME,        
 --@IxFirstColumn BIT,        
 --@ColumnIDInTable INT,        
 --@ColumnIDInIndex INT,        
 --@IsIncludedColumn INT,        
 --@sIncludeCols VARCHAR(MAX),        
 --@sIndexCols VARCHAR(MAX),        
 --@sSQL VARCHAR(MAX),        
 --@sParamSQL VARCHAR(MAX),        
 --@sFilterSQL VARCHAR(MAX),        
 --@location SYSNAME,        
 --@IndexCount INT,        
 --@CurrentIndex INT,        
 --@CurrentCol INT,        
 --@Name VARCHAR(128),        
 --@IsPrimaryKey TINYINT,        
 --@Fillfactor INT,        
 --@FilterDefinition VARCHAR(MAX),        
 --@IsClustered BIT         
 IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'[tempdb].[dbo].[#IndexSQL]'))        
 DROP TABLE [dbo].[#IndexSQL]        
 CREATE TABLE #IndexSQL        
 ( TableName VARCHAR(128) NOT NULL        
  ,IndexName VARCHAR(128) NOT NULL        
  ,IsClustered BIT NOT NULL        
  ,IsPrimaryKey BIT NOT NULL        
  ,IndexCreateSQL VARCHAR(max) NOT NULL        
 )        
 IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'[tempdb].[dbo].[#IndexListing]'))        
 DROP TABLE [dbo].[#IndexListing]        
 CREATE TABLE #IndexListing        
 (        
 [IndexListingID] INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,        
 [TableName] SYSNAME COLLATE SQL_Latin1_General_CP1_CI_AS NULL,        
 [ObjectID] INT NOT NULL,        
 [IndexName] SYSNAME COLLATE SQL_Latin1_General_CP1_CI_AS NULL,        
 [IndexID] INT NOT NULL,        
 [IsPrimaryKey] TINYINT NOT NULL,        
 [FillFactor] INT,        
 [FilterDefinition] NVARCHAR(MAX) NULL        
 )        
 IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE id = object_id(N'[tempdb].[dbo].[#ColumnListing]'))        
 DROP TABLE [dbo].[#ColumnListing]        
 CREATE TABLE #ColumnListing        
 (        
 [ColumnListingID] INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,        
 [ColumnIDInTable] INT NOT NULL,        
 [Name] SYSNAME COLLATE SQL_Latin1_General_CP1_CI_AS NULL,        
 [ColumnIDInIndex] INT NOT NULL,        
 [IsIncludedColumn] BIT NULL        
 )        
 INSERT INTO #IndexListing( [TableName], [ObjectID], [IndexName], [IndexID], [IsPrimaryKey], [FILLFACTOR], [FilterDefinition] )        
 SELECT OBJECT_NAME(si.object_id), si.object_id, si.name, si.index_id, si.Is_Primary_Key, si.Fill_Factor, si.filter_definition        
 FROM sys.indexes si        
 LEFT OUTER JOIN information_schema.table_constraints tc ON si.name = tc.constraint_name AND OBJECT_NAME(si.object_id) = tc.table_name        
 WHERE OBJECTPROPERTY(si.object_id, 'IsUserTable') = 1        
 ORDER BY OBJECT_NAME(si.object_id), si.index_id        
 SELECT @IndexCount = @@ROWCOUNT, @CurrentIndex = 1        
 WHILE @CurrentIndex <= @IndexCount        
 BEGIN        
      SELECT @idxTableName = [TableName],        
      @idxTableID = [ObjectID],        
      @idxname = [IndexName],        
      @idxid = [IndexID],        
      @IsPrimaryKey = [IsPrimaryKey],        
      @FillFactor = [FILLFACTOR],        
      @FilterDefinition = [FilterDefinition]        
      FROM #IndexListing        
      WHERE [IndexListingID] = @CurrentIndex        
      -- So - it is either an index or a constraint        
      -- Check if the index is unique        
      IF (@IsPrimaryKey = 1)        
      BEGIN        
   SET @sSQL = 'ALTER TABLE [dbo].[' + @idxTableName + '] ADD CONSTRAINT [' + @idxname + '] PRIMARY KEY '        
    -- Check if the index is clustered        
   IF (INDEXPROPERTY(@idxTableID, @idxname, 'IsClustered') = 0)        
   BEGIN        
    SET @sSQL = @sSQL + 'NON'        
    SET @IsClustered = 0        
   END        
   ELSE        
   BEGIN        
    SET @IsClustered = 1        
   END        
   SET @sSQL = @sSQL + 'CLUSTERED' + CHAR(13) + '(' + CHAR(13)        
      END        
      ELSE        
      BEGIN        
   SET @sSQL = 'CREATE '        
   -- Check if the index is unique        
   IF (INDEXPROPERTY(@idxTableID, @idxname, 'IsUnique') = 1)        
   BEGIN        
    SET @sSQL = @sSQL + 'UNIQUE '        
   END        
    -- Check if the index is clustered        
    IF (INDEXPROPERTY(@idxTableID, @idxname, 'IsClustered') = 1)        
    BEGIN  
     SET @sSQL = @sSQL + 'CLUSTERED '        
     SET @IsClustered = 1        
    END        
    ELSE        
    BEGIN        
     SET @IsClustered = 0        
    END        
    SELECT  @sSQL = @sSQL + 'INDEX [' + @idxname + '] ON [dbo].[' + @idxTableName + ']' + CHAR(13) + '(' + CHAR(13),  @colCount = 0,        
     @colCountMinusIncludedColumns = 0        
   END        
         
   -- Get the nuthe mber of cols in the index        
   SELECT @colCount = COUNT(*),        
    @colCountMinusIncludedColumns = SUM(CASE ic.is_included_column WHEN 0 THEN 1 ELSE 0 END)        
    FROM sys.index_columns ic        
    INNER JOIN sys.columns sc ON ic.object_id = sc.object_id AND ic.column_id = sc.column_id        
    WHERE ic.object_id = @idxtableid AND index_id = @idxid        
    -- Get the file group info        
    SELECT @location = f.[name]        
    FROM sys.indexes i        
    INNER JOIN sys.filegroups f ON i.data_space_id = f.data_space_id        
INNER JOIN sys.all_objects o ON i.[object_id] = o.[object_id]        
    WHERE o.object_id = @idxTableID AND i.index_id = @idxid        
    -- Get all columns of the index        
    INSERT INTO #ColumnListing( [ColumnIDInTable], [Name], [ColumnIDInIndex],[IsIncludedColumn] )        
    SELECT sc.column_id, sc.name, ic.index_column_id, ic.is_included_column        
    FROM sys.index_columns ic        
    INNER JOIN sys.columns sc ON ic.object_id = sc.object_id AND ic.column_id = sc.column_id        
      WHERE ic.object_id = @idxTableID AND index_id = @idxid        
      ORDER BY ic.index_column_id        
      IF @@ROWCOUNT > 0        
      BEGIN        
      SELECT @CurrentCol = 1        
      SELECT @IxFirstColumn = 1, @sIncludeCols = '', @sIndexCols = ''        
      WHILE @CurrentCol <= @ColCount        
      BEGIN        
           SELECT @ColumnIDInTable = ColumnIDInTable,        
           @Name = Name,        
           @ColumnIDInIndex = ColumnIDInIndex,        
           @IsIncludedColumn = IsIncludedColumn        
           FROM #ColumnListing        
           WHERE [ColumnListingID] = @CurrentCol        
           IF @IsIncludedColumn = 0        
           BEGIN        
                SELECT @sIndexCols = CHAR(9) + @sIndexCols + '[' + @Name + '] '        
                -- Check the sort order of the index cols ????????        
                   
                IF @CurrentCol < @colCountMinusIncludedColumns        
                     BEGIN        
                     SET @sIndexCols = @sIndexCols + ', '        
                     END        
           END        
           ELSE        
           BEGIN        
                -- Check for any include columns        
                IF LEN(@sIncludeCols) > 0        
                     BEGIN        
                     SET @sIncludeCols = @sIncludeCols + ','        
                     END        
                SELECT @sIncludeCols = @sIncludeCols + '[' + @Name + ']'        
           END        
                SET @CurrentCol = @CurrentCol + 1        
      END        
      TRUNCATE TABLE #ColumnListing        
      --append to the result        
      IF LEN(@sIncludeCols) > 0        
           SET @sIndexCols = @sSQL + @sIndexCols + CHAR(13) + ') ' + ' INCLUDE ( ' + @sIncludeCols + ' ) '        
      ELSE        
           SET @sIndexCols = @sSQL + @sIndexCols + CHAR(13) + ') '        
      
            
      SET @sSQL = @sIndexCols + CHAR(13)       
      -- 2008 R2 allows ON [filegroup] for primary keys as well, negating the old "IF THE INDEX IS NOT A PRIMARY KEY - ADD THIS - ELSE DO NOT" IsPrimaryKey IF statement        
 --PRINT @sIndexCols + CHAR(13)        
      INSERT INTO #IndexSQL (TableName, IndexName, IsClustered, IsPrimaryKey, IndexCreateSQL) VALUES (@idxTableName, @idxName, @IsClustered, @IsPrimaryKey, @sSQL)        
      END        
      SET @CurrentIndex = @CurrentIndex + 1        
 END        
 Select nome, Source AS TEXT From #Text        
 UNION ALL        
 SELECT IndexName, indexcreateSQL FROM #IndexSQL        
 WHERE tablename= (CASE WHEN @TableName =NULL THEN tablename ELSE @TableName END)        
 SET NOCOUNT OFF 
 
