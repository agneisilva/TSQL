  
--EXEC SCRIPT_CRIACAO_FK 'DOCUMENTO_tB'   
CREATE PROCEDURE SCRIPT_CRIACAO_FK  
(  
@NOME_TAB VARCHAR(100)  
)  
  
AS   
  
BEGIN  
  
DECLARE @SCHEMA_NAME SYSNAME;  
DECLARE @TABLE_NAME  SYSNAME ;  
DECLARE @CONSTRAINT_NAME SYSNAME;  
DECLARE @CONSTRAINT_OBJECT_ID INT;  
DECLARE @REFERENCED_OBJECT_NAME SYSNAME;  
DECLARE @IS_DISABLED BIT =  1;  
DECLARE @IS_NOT_FOR_REPLICATION BIT;  
DECLARE @IS_NOT_TRUSTED BIT = 1;  
DECLARE @DELETE_REFERENTIAL_ACTION TINYINT;  
DECLARE @UPDATE_REFERENTIAL_ACTION TINYINT;  
DECLARE @TSQL NVARCHAR(4000);  
DECLARE @TSQL2 NVARCHAR(4000);  
DECLARE @FKCOL SYSNAME;  
DECLARE @PKCOL SYSNAME;  
DECLARE @COL1 BIT;  
DECLARE @ACTION CHAR(6);  
  
--SET @ACTION = 'DROP';  
  
SET @ACTION = 'CREATE';  
  
DECLARE FKCURSOR CURSOR FOR  
  
    SELECT OBJECT_SCHEMA_NAME(PARENT_OBJECT_ID)  
  
         , OBJECT_NAME(PARENT_OBJECT_ID), NAME, OBJECT_NAME(REFERENCED_OBJECT_ID)  
  
         , OBJECT_ID  
  
         , IS_DISABLED, IS_NOT_FOR_REPLICATION, IS_NOT_TRUSTED  
  
         , DELETE_REFERENTIAL_ACTION, UPDATE_REFERENTIAL_ACTION  
     
FROM SYS.FOREIGN_KEYS  WHERE  OBJECT_NAME(PARENT_OBJECT_ID)  = ISNULL( @NOME_TAB,OBJECT_NAME(PARENT_OBJECT_ID) )   
  
    ORDER BY 1,2;  
  
  
 IF OBJECT_ID('TEMPDB..#AUX_FK') IS NOT NULL  
 BEGIN  
 DROP TABLE  #AUX_FK  
 END  
  
 CREATE TABLE #AUX_FK  
 (  
 NOME_TABELA VARCHAR(100)  
 ,SCRIPT_CRIACAO_FK VARCHAR(MAX)  
 ,NOME_CONSTRAINT VARCHAR(100)  
   
 )  
  
OPEN FKCURSOR;  
  
  
  
FETCH NEXT FROM FKCURSOR INTO @SCHEMA_NAME, @TABLE_NAME, @CONSTRAINT_NAME  
  
    , @REFERENCED_OBJECT_NAME, @CONSTRAINT_OBJECT_ID  
  
    , @IS_DISABLED, @IS_NOT_FOR_REPLICATION, @IS_NOT_TRUSTED  
  
    , @DELETE_REFERENTIAL_ACTION, @UPDATE_REFERENTIAL_ACTION;  
  
  
  
WHILE @@FETCH_STATUS = 0  
  
  
  
BEGIN  
  
    IF @ACTION <> 'CREATE'  
  
        SET @TSQL = 'ALTER TABLE '  
  
                  + QUOTENAME(@SCHEMA_NAME) + '.' + QUOTENAME(@TABLE_NAME)  
  
                  + ' DROP CONSTRAINT ' + QUOTENAME(@CONSTRAINT_NAME) + ';';  
  
    ELSE  
  
        BEGIN  
  
        SET @TSQL = 'ALTER TABLE '  
  
                  + QUOTENAME(@SCHEMA_NAME) + '.' + QUOTENAME(@TABLE_NAME)  
  
                 -- + CASE @IS_NOT_TRUSTED  
     --  
                 --       WHEN 0 THEN ' WITH CHECK '  
     --  
                 --       ELSE ' WITH NOCHECK '  
     --  
                 --   END  
  
                  + ' ADD CONSTRAINT ' + QUOTENAME(@CONSTRAINT_NAME)  
  
                  + ' FOREIGN KEY ('  
  
        SET @TSQL2 = '';  
  
        DECLARE COLUMNCURSOR CURSOR FOR  
  
            SELECT COL_NAME(FK.PARENT_OBJECT_ID, FKC.PARENT_COLUMN_ID)  
  
                 , COL_NAME(FK.REFERENCED_OBJECT_ID, FKC.REFERENCED_COLUMN_ID)  
  
            FROM SYS.FOREIGN_KEYS FK  
  
INNER JOIN SYS.FOREIGN_KEY_COLUMNS FKC  
  
            ON FK.OBJECT_ID = FKC.CONSTRAINT_OBJECT_ID  
  
            WHERE FKC.CONSTRAINT_OBJECT_ID = @CONSTRAINT_OBJECT_ID  
  
            ORDER BY FKC.CONSTRAINT_COLUMN_ID;  
  
        OPEN COLUMNCURSOR;  
  
  
  
        SET @COL1 = 1;  
  
  
  
        FETCH NEXT FROM COLUMNCURSOR INTO @FKCOL, @PKCOL;  
  
WHILE @@FETCH_STATUS = 0  
  
        BEGIN  
  
            IF (@COL1 = 1)  
  
                SET @COL1 = 0  
  
            ELSE  
  
            BEGIN  
  
                SET @TSQL = @TSQL + ',';  
  
                SET @TSQL2 = @TSQL2 + ',';  
  
            END;  
  
            SET @TSQL = @TSQL + QUOTENAME(@FKCOL);  
  
            SET @TSQL2 = @TSQL2 + QUOTENAME(@PKCOL);  
  
            FETCH NEXT FROM COLUMNCURSOR INTO @FKCOL, @PKCOL;  
  
        END;  
  
        CLOSE COLUMNCURSOR;  
  
        DEALLOCATE COLUMNCURSOR;  
  
  
  
        SET @TSQL = @TSQL + ' ) REFERENCES ' + QUOTENAME(@SCHEMA_NAME) + '.' + QUOTENAME(@REFERENCED_OBJECT_NAME)  
  
                  + ' (' + @TSQL2 + ')';             
  
  
  
        SET @TSQL =  @TSQL  
  
                  --+ ' ON UPDATE ' + CASE @UPDATE_REFERENTIAL_ACTION  
  
                  --                      WHEN 0 THEN 'NO ACTION '  
  
                  --                      WHEN 1 THEN 'CASCADE '  
  
                  --      WHEN 2 THEN 'SET NULL '  
  
                  --                      ELSE 'SET DEFAULT '  
  
                  --                  END  
  
                  --+ ' ON DELETE ' + CASE @DELETE_REFERENTIAL_ACTION  
  
                  --                      WHEN 0 THEN 'NO ACTION '  
  
                  --                      WHEN 1 THEN 'CASCADE '  
  
                  --                      WHEN 2 THEN 'SET NULL '  
  
                  --                      ELSE 'SET DEFAULT '  
  
                  --                  END  
  
                  + CASE @IS_NOT_FOR_REPLICATION  
  
                        WHEN 1 THEN ' NOT FOR REPLICATION '  
  
                        ELSE ''  
  
                    END  
  
                 -- + ';'  
     ;  
  
  
  
        END;  
  
  
  
  
INSERT INTO #AUX_FK  
SELECT @TABLE_NAME,@TSQL,@CONSTRAINT_NAME  
    --PRINT @TSQL;  
  
    IF @ACTION = 'CREATE'  
  
        BEGIN  
  
        SET @TSQL = 'ALTER TABLE '  
  
                  + QUOTENAME(@SCHEMA_NAME) + '.' + QUOTENAME(@TABLE_NAME)  
  
                --  + CASE @IS_DISABLED  
    --  
                --        WHEN 0 THEN ' CHECK '  
    --  
                --        ELSE ' NOCHECK '  
    --  
                --    END  
  
                  + 'CONSTRAINT ' + QUOTENAME(@CONSTRAINT_NAME)  
  
                  + ';';  
  
        --PRINT @TSQL;  
  
        END;  
  
  
  
    FETCH NEXT FROM FKCURSOR INTO @SCHEMA_NAME, @TABLE_NAME, @CONSTRAINT_NAME  
  
        , @REFERENCED_OBJECT_NAME, @CONSTRAINT_OBJECT_ID  
  
        , @IS_DISABLED, @IS_NOT_FOR_REPLICATION, @IS_NOT_TRUSTED  
  
        , @DELETE_REFERENTIAL_ACTION, @UPDATE_REFERENTIAL_ACTION;  
END;  
CLOSE FKCURSOR;  
DEALLOCATE FKCURSOR;  
  
SELECT * FROM #AUX_FK  
  
  
END

