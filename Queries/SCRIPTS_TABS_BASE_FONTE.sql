                                    
CREATE  PROCEDURE SCRIPTS_TABS_BASE_FONTE (                                    
@chaves char(1) = 's'                           
,@APENAS_COLUNAS CHAR(1) =  'N'                       
,@NOME_TABELA Nvarchar(2000)   =  NULL                                    
)                                    
AS                                    
BEGIN                  
            
/*            
Leandro Sampaio            
Script criação de tabela, PK,FK, INDEX E UKS            
*/            
               
declare @objs varchar(8000)                        
if @NOME_TABELA is not null  
begin  
select @objs = 'select name, id from sys.sysobjects where name in(''' + REPLACE(replace(replace(@NOME_TABELA,' ',''),' ',''), ',',''',''')  + ''') order by id'                       
end  
else   
               
set @objs =  'select name, id =  object_id from sys.tables where  type = '+ '''u'''  
  
  
create table #table (name varchar(256), id int)                        
insert into #table  exec (@objs)             
            
                                    
---PROC PARAR CRIAR OU EQUALIZAR TABELAS ENTRE BASES DIFERENTES--                                    
                                    
if OBJECT_ID('tempdb..#aux_base_fonte') is not null                                    
begin                                    
                                    
drop table #aux_base_fonte                                    
end                                    
------------------------------------Pegar informações das tabelas da base alvo                                    
select  b.name as nome_tabela, a.name as nome_coluna, d.DATA_TYPE as tipo_col,                                    
tamanho_col = case when DATA_TYPE in('int','bigint','date','datetime','smalldatetime') then '0'                                     
when DATA_TYPE in('char','varchar','nchar','ntext','nvarchar','xml') then convert(varchar(10),CHARACTER_MAXIMUM_LENGTH)                                    
when DATA_TYPE in('numeric') then  convert(varchar(10),NUMERIC_PRECISION )+','+ convert(varchar(10),NUMERIC_SCALE) end                                    
,identiti =  case when a.is_identity =  1 then  'S' else 'N'end                                     
,aceita_nul  =case when a.is_nullable =  1 then 's' else 'n' end                                    
,id = null                                    
into #aux_base_fonte                                    
from sys.columns  a                                     
inner join sys.tables b                                    
on a.object_id =  b.object_id                                    
inner join INFORMATION_SCHEMA.COLUMNS d                                    
on b.name =  d.TABLE_NAME                                    
and a.name =  d.COLUMN_NAME                                    
where b.type =  'U'                                    
AND b.object_id in  (select distinct id from #table)--  = ISNULL(@NOME_TABELA,b.name)                                    
order by a.column_id              
              
              
                                    
                                    
---1 Verificar as tabelas que não existem na base alvo, mas existem na base fonte                                    
                                    
if OBJECT_ID('tempdb..#aux_id') is not null                                    
begin                                    
drop table #aux_id                                    
end                                    
                                    
                                    
select distinct                                     
a.nome_tabela                                     
 ,id = IDENTITY(int)                    
 into #aux_id                                     
 from #aux_base_fonte a                                     
                    
 update a                                     
 set  a.id =  b.id                                    
 --select *                                     
 from  #aux_base_fonte a                                     
 inner join #aux_id b                                    
 on a.nome_tabela =  b.nome_tabela                                    
                                    
                        
                                    
                                    
                                    
                                    
 update  a                             
 set a.tamanho_col = case when  tamanho_col =  '-1'  then 'max' else '' end                                    
 --select *                                     
 from  #aux_base_fonte a                                     
 where tamanho_col in ('-1' ,'null')                                    
                                     
 if OBJECT_ID('tempdb..##resul_') is not null                                    
 begin                                    
 drop table ##resul_                                    
 end                                    
                                    
 CREATE TABLE ##RESUL_ (                                    
 NOME_TABELA     VARCHAR(150)                                    
 ,SCRIPT_CRIAÇÃO_TABELA VARCHAR(MAX)                                    
 ,SCRIPT_CRIAÇÃO_FKS VARCHAR(MAX)                                    
 ,SCRIPT_CRIAÇÃO_INDEX VARCHAR(MAX)                                 
 ,SCRIPT_CRIAÇÃO_PKS  VARCHAR(MAX)                       
 ,SCRIPT_CRIAÇÃO_UQS  VARCHAR(MAX)                   
               
 )                                    
                                    
                                    
 -------------------------------------------Criação de index-------                                    
                                    
                                    
  if object_id ('tempdb..#aux_index')  is not null                                    
  begin                                    
  drop table #aux_index                                    
  end                                    
                
create table  #aux_index (                
[schema]           varchar(max) null                
,[nome_tab]     varchar(max) null                
,[TIPO_INDEX]    varchar(max) null                
,[CHAVE]     varchar(max) null                
,[ISUNIQUE]     varchar(max) null                
,[UQ_CONSTRAINT]   varchar(max) null                
,[nome_indice]    varchar(max) null                
,[nome_coluna]    varchar(max) null                
,[included]     varchar(max) null                
,[FILTO]     varchar(max) null                
,[LINHA_INDICE]    VARCHAR(MAX)                         
)                
                
insert into #aux_index                                   
 SELECT s.name as [schema], t.name as [nome_tab]                                    
                                     
-- Detalhes do índice                                    
, i.[type_desc]            AS TIPO_INDEX                                    
, i.[is_primary_key]    AS CHAVE                                    
, i.[is_unique]      AS  ISUNIQUE                                    
, i.[is_unique_constraint] AS  UQ_CONSTRAINT                                    
, ISNULL(i.name, '') AS [nome_indice]                                    
, ISNULL(SUBSTRING(c.[indexed], 0, LEN(c.[indexed])), '') AS   [nome_coluna]                                    
, ISNULL(SUBSTRING(c.[included], 0, LEN(c.[included])), '') AS [included]                                    
                                     
-- Filtro utilizado pelo índice                                    
, ISNULL(i.filter_definition, '') AS FILTO                       
,[LINHA_INDICE]  = null                             
 --into #aux_index                                    
FROM sys.schemas s                                    
INNER JOIN sys.tables t         
ON s.[schema_id] = t.[schema_id]                                    
INNER JOIN sys.indexes i                                    
ON t.[object_id] = i.[object_id]                                    
                                     
-- Relação de colunas que formam o índice                                    
CROSS APPLY (                                    
    SELECT (                      
        SELECT c.name + ', '                                    
        FROM sys.columns c                                    
        INNER JOIN sys.index_columns ic                                    
        ON c.[object_id] = ic.[object_id]                                    
        AND c.[column_id] = ic.[column_id]                                    
        WHERE t.[object_id] = c.[object_id]                                    
        AND ic.[index_id] = i.[index_id]                                    
        AND ic.[is_included_column] = 0                                    
        ORDER BY [key_ordinal]                                   
        FOR XML PATH('')                                    
    ) AS [indexed]                                    
    ,(                                    
        SELECT c.name + ', '                                    
        FROM sys.columns c                                    
        INNER JOIN sys.index_columns ic                        
        ON c.[object_id] = ic.[object_id]                                    
        AND c.[column_id] = ic.[column_id]                                    
        WHERE t.[object_id] = c.[object_id]                                    
        AND ic.[index_id] = i.[index_id]                                    
        AND ic.[is_included_column] = 1                           
        ORDER BY [key_ordinal]                                    
        FOR XML PATH('')                                    
    ) AS [included]                                    
) AS c                                    
where i.[type_desc]  in ('nonclustered','clustered')                                    
AND  t.object_id in  (select distinct id from #table)--  = ISNULL(@NOME_TABELA,b.name)  --T.name  = ISNULL(@NOME_TABELA,t.name)        
and i.is_primary_key = 0         
ORDER BY [schema], [nome_tab]                                    
                                    
                
                
update b                
set [included] =  null                
 --select *                
 from #aux_index  b where      [included] =  ''                  
                                    
--SELECT                                    
UPDATE  A                                    
SET A.LINHA_INDICE =  'IF (not EXISTS (                                    
select top 1 1  from sys.indexes a inner join sys.tables b on a.object_id   =  b.object_id  where a.name =' + '''' + nome_indice +'''' +           
' and b.name = ' +''''+ [nome_tab] +'''' +       
                              
'))                                    
BEGIN                                    
'                                    
 +                                
 'CREATE  ' +  CASE WHEN ISUNIQUE =  1 THEN  'UNIQUE  ' ELSE '' END + '' + TIPO_INDEX +' ' + ' INDEX  '+ nome_indice + ' ' + ' ON ' + nome_tab +' ('+ nome_coluna + ')'                          
 + case when [included] Is not null  then '  INCLUDE '   +   '(' + [included] + ')' else '' end                         
+                                 
'                                    
  END                                     
'                                      
                                
                       
--SELECT *                                    
FROM #aux_index A                
              
              
              
              
                                   
IF @APENAS_COLUNAS =  's'                                    
begin              
 IF OBJECT_ID('TEMPDB..##AUX_SELECT_COLUNAS') IS NOT NULL                                    
 BEGIN                               
 DROP TABLE ##AUX_SELECT_COLUNAS                 
 end                
 create table ##AUX_SELECT_COLUNAS (              
               
 nome_tabela           varchar(max)              
 ,Script_criacao_coluna varchar(max)              
 )              
               
 end                          
                               
                                      
                                    
----------------------------------------fIM iNDEX------------------                        
      
                                
 ------------------------------------------ FIM  FOREGINGS KEYS                        
                                
 --------------------------- CRIAÇÃO DAS TABELAS---                                    
 declare @qts_tabelas int , @aux_cont int = 1                                    
                                    
 select @qts_tabelas  = COUNT('') from #aux_id                                    
                                    
                               
                                    
                                    
 begin try                                    
                                     
                                    
 while  @aux_cont <=  @qts_tabelas                                    
 begin                            
declare                                    
 @SQL VARCHAR(max)= ''                                     
 ,@aux VARCHAR(max) = ''                                    
 , @nome_tab VARCHAR(100)                                     
 ,@exec  varchar(max)                                    
 ,@verificar_tab varchar(max)                                    
 ,@INDEX VARCHAR(MAX)                                    
 ,@PRIMARY_KEY VARCHAR(MAX)                    
 ,@aux_primary_key varchar(max)              
 ,@nome_constraint_pk VARCHAR(MAX)                    
 ,@nome_constraint_uk VARCHAR(MAX)                             
 if OBJECT_ID('tempdb..#aux_insert') is not null                                    
 begin                                    
 drop table #aux_insert                                    
 end                                    
 select a.* into #aux_insert from #aux_base_fonte a                                     
 where a.id = @aux_cont                                    
                                 
                                     
                                     
                                    
                                    
  IF OBJECT_ID('TEMPDB..#AUX_INSERE_LINHA') IS NOT NULL                                    
 BEGIN                                    
 DROP TABLE #AUX_INSERE_LINHA                                    
 END                
               
                  
 select                                      
 nome_tabela                 
 ,Script_criacao_coluna =  'IF (not EXISTS (                 
select top 1 1  from sys.COLUMNS a              
inner join sys.tables b              
on a.object_id =  b.object_id              
 where a.name =' + '''' +nome_coluna +''''               
 +' and  b.name = '  + '''' +nome_tabela +''''               
 +                              
                              
'))                              
BEGIN                              
'               
+' alter table  ' +nome_tabela + ' add ' +  '['+ nome_coluna + '] '                                
 + ' '                                
 + '[' +tipo_col +'] '  
 + case when identiti = 'S' then 'identity' else '' end                                  
 + CASE WHEN tipo_col IN('CHAR','VARCHAR','nVARCHAR','NUMERIC') THEN '('+tamanho_col+ ')' ELSE '' END                                 
 + case when aceita_nul = 'S' then ' NULL ' ELSE ' NOT NULL ' END               
 +              
 'END '              
              
              
              
              
 ,LINHA = '['+ nome_coluna + '] '                                
 + ' '                                
 + '[' +tipo_col +'] '             
 + case when identiti = 'S' then 'identity' else '' end                                  
 + CASE WHEN tipo_col IN('CHAR','VARCHAR','nVARCHAR','NUMERIC') THEN '('+tamanho_col+ ')' ELSE '' END                                 
 + case when aceita_nul = 'S' then ' NULL ' ELSE ' NOT NULL ' END                                      
 ,ID =  IDENTITY(INT)                                    
 INTO #AUX_INSERE_LINHA                                    
 from #aux_insert                
               
                                 
IF @APENAS_COLUNAS =  's'                
begin              
 insert into ##AUX_SELECT_COLUNAS(nome_tabela,Script_criacao_coluna)              
 select nome_tabela,Script_criacao_coluna from    #AUX_INSERE_LINHA                              
 end              
                                
                                    
 select top 1 @nome_tab =  nome_tabela from #AUX_INSERE_LINHA                                    
                                    
                                     
 IF OBJECT_ID('TEMPDB..#AUX_INSERT_INDEX ')IS NOT NULL                                    
 BEGIN                                    
 DROP TABLE #AUX_INSERT_INDEX                                     
 END                                    
                                    
                                               
 SELECT                                     
   LINHA_INDICE                                     
   ,nome_tab AS  nome_tab                 
              
   ,ID = IDENTITY(INT)                                    
   INTO #AUX_INSERT_INDEX                                     
 FROM #aux_index  WHERE nome_tab =  @nome_tab                      
                   
                   
                   
                   
------------------------------------------inICIO  fOREINGS kEYS------------                        
IF OBJECT_ID('TEMPDB..#AUX_fks')         IS NOT NULL                        
BEGIN                        
DROP TABLE #AUX_fks                        
END                        
                    
CREATE TABLE  #AUX_fks                  
 (                  
 nome_tabela VARCHAR(100)                  
 ,LINHA_fk VARCHAR(MAX)         
 ,NOME_CONSTRAINT VARCHAR(100)                  
                   
 )                  
                    
  INSERT INTO     #AUX_fks                  
EXEC SCRIPT_CRIACAO_FK  @nome_tab                  
                  
                  
UPDATE A                  
SET A.LINHA_fk =  'IF (not EXISTS (                 
select top 1 1  from sys.foreign_keys where name =' + '''' +NOME_CONSTRAINT +'''' +                              
                              
'))                              
BEGIN                              
'  + LINHA_fk + 'END '                  
--SELECT *                   
FROM  #AUX_fks A                   
                                      
                           
                                    
                        
------Tabela_auxiliar_pks                  
                        
                        
               
 IF OBJECT_ID('TEMPDB..#AUX_INSERT_FKS ')IS NOT NULL                                    
 BEGIN                                    
 DROP TABLE #AUX_INSERT_FKS                                     
 END                                
select  DISTINCT                        
linha_FK                        
,nome_tabela                        
,ID = IDENTITY(INT)                        
INTO #AUX_INSERT_FKS                         
 from #AUX_fks   WHERE nome_tabela = @nome_tab                      
                        
              
              
              
                      
                                    
                                     
 DECLARE @QTD_LINHAS INT, @CONT INT = 1                
                                    
 SELECT  @QTD_LINHAS = COUNT('')  FROM #AUX_INSERE_LINHA                                    
                                    
 WHILE @CONT <= @QTD_LINHAS                                    
 BEGIN                                 
                                    
                                    
 select  @SQL  = LINHA   FROM  #AUX_INSERE_LINHA WHERE ID = @CONT                                    
                                     
 set @aux +=  @SQL +' , '                 
               
                                     
                                    
 DELETE FROM #AUX_INSERE_LINHA WHERE ID =  @CONT                                    
 SET @CONT += 1                                    
 END                                    
                                    
                                    
 ----------------- LOOP PARA PEGAR OS INDEX                                     
                                     
                                     
                                    
                                     
 DECLARE @QTDS_INDEX INT, @CONT_INDEX INT =  1 , @INICIALIZADOR_INDEX VARCHAR(MAX) =  '', @INDEX_DINAMICO VARCHAR(MAX) = ''                                    
                                    
 SELECT  @QTDS_INDEX  = COUNT('')  FROM #AUX_INSERT_INDEX --WHERE nome_tab =  @nome_tab                                    
                                    
 WHILE  @CONT_INDEX <=  @QTDS_INDEX                                    
 BEGIN                                    
                                    
                                    
                                     
 select  @INDEX_DINAMICO  = LINHA_INDICE FROM  #AUX_INSERT_INDEX  WHERE ID = @CONT_INDEX                                    
                                     
                                      
 set @INICIALIZADOR_INDEX += ' ' + @INDEX_DINAMICO                                 
                                     
                       
 DELETE FROM #AUX_INSERT_INDEX  WHERE ID =  @CONT_INDEX                                    
 SET @CONT_INDEX += 1                                    
 --#AUX_INSERT_INDEX                                     
                                    
 END                           
 ---------------------lOOP PARA MONTAR AS PKS-------                        
                         
                                    
 DECLARE @QTDS_FK INT, @CONT_FK INT =  1 , @INICIALIZADOR_FK VARCHAR(MAX) =  '', @INDEX_FK VARCHAR(MAX) = ''                                    
                                    
 SELECT  @QTDS_FK  = COUNT('')  FROM #AUX_INSERT_FKS--WHERE nome_tab =  @nome_tab                                    
                                    
 WHILE  @CONT_FK <=  @QTDS_FK                                    
 BEGIN                                    
                                     
 select  @INDEX_FK = LINHA_FK FROM  #AUX_INSERT_FKS WHERE ID = @CONT_FK                                    
                                 
                                      
 set @INICIALIZADOR_FK += ' ' + @INDEX_FK                                  
                                     
                                    
 DELETE FROM #AUX_INSERT_FKS  WHERE ID =  @CONT_FK                                    
 SET @CONT_FK += 1                                    
 --#AUX_INSERT_INDEX                      
                                    
 END                          
 --SELECT  @INICIALIZADOR_FK                        
                                  
                                    
 --------------------------------------------------                                    
                                    
 -----Loop para pegar pks                                    
 if @chaves = 'S'                                    
 BEGIN                                    
                              
 if OBJECT_ID('tempdb..#aux_pks') is not null                                    
 begin                          
 drop table #aux_pks                                    
 end                                    
                                    
 create table #aux_pks                                     
 (                   
 nome_tabela varchar(max)                                    
 ,script_pks varchar(max)                                 
 ,NOME_CONSTRAINT varchar(max)                
 ,xtype char(5)                               
 ,ID INT IDENTITY                                    
 )                                    
                                    
                                    
                                    
 insert into #aux_pks  (nome_tabela,script_pks,NOME_CONSTRAINT,xtype)                                  
 exec SCRIPT_CRIAÇÃO_PK_UQ  @nome_tab                                    
                              
 SET @aux_primary_key = ''                          
 SELECT @aux_primary_key =   script_pks, @nome_constraint_pk = NOME_CONSTRAINT   from #aux_pks WHERE xtype =  'PK'                  
              
 if @aux_primary_key =  ''              
 begin              
  set @PRIMARY_KEY = ''              
  end              
  else                             
set  @PRIMARY_KEY =                  
              
'IF (NOT EXISTS (                 
SELECT top 1 1  FROM SYS.INDEXES WHERE NAME =' + '''' +@NOME_CONSTRAINT_PK +''''+' )) ' +  ' BEGIN ' + @aux_primary_key + ' END'                                      
                                    
                                      
 if OBJECT_ID('tempdb..#aux_pks_fks') is not null                                    
 begin                                    
 drop table #aux_pks_fks                                   
 end                                    
                                    
 select                                     
 distinct                                     
 script_pks                  
 ,NOME_CONSTRAINT                                
 ,ID = IDENTITY(int)                                    
 into #aux_pks_fks                                    
  from  #aux_pks           where xtype =  'UQ'                          
                                    
                                    
                                      
                                     
 DECLARE @QTDS_PKS INT, @CONT_PKS INT =  1 , @INICIALIZADOR_PKS VARCHAR(MAX) =  '', @PKS_DINAMICO VARCHAR(MAX) = ''                                    
                                    
                                     
                                     
 SELECT  @QTDS_pks  = COUNT('')  FROM #aux_pks_fks --WHERE nome_tab =  @nome_tab                                    
                                    
 WHILE  @CONT_PKS <=  @QTDS_pks                                    
 BEGIN                                    
                                    
                                    
                                     
 select  @PKS_DINAMICO  = script_pks, @nome_constraint_uk =  NOME_CONSTRAINT FROM  #aux_pks_fks  WHERE ID = @CONT_PKS                                    
                              
                                      
 set @INICIALIZADOR_PKS += ' ' + @PKS_DINAMICO                 
               
               
       
 if @PKS_DINAMICO =  ''              
 begin              
  set @INICIALIZADOR_PKS = ''              
  end              
  else                             
set  @INICIALIZADOR_PKS =                  
              
'IF (NOT EXISTS (                 
SELECT top 1 1  FROM SYS.INDEXES WHERE NAME =' + '''' +@nome_constraint_uk +''''+' )) ' +  ' BEGIN ' + @INICIALIZADOR_PKS + ' END'                   
                                    
                                     
                                    
 DELETE FROM #aux_pks_fks  WHERE ID =  @CONT_PKS                                    
 SET @CONT_PKS += 1                                    
                                     
                                    
 END                                    
                                    
 END --- VERIFICA CHAVES                                     
                                    
 --------------------------------------------------                                    
               
 set @exec = 'create table ' + @nome_tab + ' ( ' + @aux + ' )'                                    
                                    
  set @verificar_tab =   'IF (not EXISTS (                                    
select top 1 1  from sys.tables where name =' + '''' + @nome_tab +'''' +                                    
                                    
'))                                    
BEGIN                                    
'                                    
+ @exec                                      
+                                 
'                                    
  END                                     
'                                      
                                  
  --SET  @INICIALIZADOR_INDEX                                        
                                    
 set @aux_cont +=1                                    
                                    
 --exec(@exec)                                    
 insert into ##resul_ (nome_tabela,script_criação_tabela,SCRIPT_CRIAÇÃO_PKS,SCRIPT_CRIAÇÃO_FKS,script_criação_INDEX ,SCRIPT_CRIAÇÃO_UQS)                                    
 select               @nome_tab,@verificar_tab,@PRIMARY_KEY,@INICIALIZADOR_FK  ,@INICIALIZADOR_INDEX  ,@INICIALIZADOR_PKS                                
                                    
--select @verificar_tab                                    
                                    
                                     
end                                    
                   
                     
if @APENAS_COLUNAS =  'N'              
BEGIN                               
select nome_tabela, script_criação_tabela AS script_criação_tabela_E_COLUNAS ,SCRIPT_CRIAÇÃO_PKS,SCRIPT_CRIAÇÃO_FKS,script_criação_INDEX ,SCRIPT_CRIAÇÃO_UQS from ##resul_                                    
end                   
if @APENAS_COLUNAS =  'S'              
BEGIN              
select nome_tabela,Script_criacao_coluna from ##AUX_SELECT_COLUNAS                
END              
                        
                                    
END TRY                                    
                                    
                                    
                                    
                                    
BEGIN CATCH                                      
                                    
                                    
                                             
  SELECT      ERROR_NUMBER()    AS ErrorNumber                                      
              ,ERROR_SEVERITY()  AS ErrorSeverity                                      
              ,ERROR_STATE()     AS ErrorState                                      
                                               
              ,ERROR_LINE()      AS ErrorLine                                      
              ,ERROR_MESSAGE()   AS ErrorMessage             
END CATCH                                       
                                      
END
