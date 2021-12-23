CREATE procedure script_insert (      
 @nome_tabela varchar(100)       
 ,@STRING   varchar(max) = NULL    
)      
      
      
as      
begin      
      
/*      
Leandro Sampaio pereira      
---Proc que criar script de insert pela tabela      
      
*/      
--declare @nome_tabela varchar(100) =  'arquivo_tb'      
      
 SET @STRING =  ISNULL(@STRING,'')  
    
    
    
set nocount on       
      
if OBJECT_ID('tempdb..#aux_insert_tab_cols') is not null      
begin      
drop table #aux_insert_tab_cols      
    
end      
      
select       
a.name as nome_tab      
, ISNULL(SUBSTRING(c.colunas, 0, LEN(c.colunas)), '') AS nome_col      
,iif(c.identiti is not null, 'S','N') as tem_identity      
,linha =  CONVERT(varchar(max),null)      
into #aux_insert_tab_cols      
from sys.tables a      
cross apply(      
select       
(      
select     '[' + b.name+ ']'  + ', '      
from sys.columns b      
where a.object_id = b.object_id      
order by b.column_id      
 FOR XML PATH('')         
) as  colunas      
,      
(      
select distinct c.name from      
sys.columns c      
where a.object_id = c.object_id      
and c.is_identity = 1      
) as identiti      
      
) as c      
where a.name = @nome_tabela      
      
      
update a      
set      
  linha =   ''''+'insert into ' + nome_tab + ' ' + ' ( '+  nome_col +' ) '  + ' values '+''''+ '+'       
from  #aux_insert_tab_cols a       
      
      
DECLARE @AUX_SCRIPT VARCHAR(MAX)      
DECLARE @AUTO_INCLEMENTO_ON VARCHAR(MAX)      
DECLARE @AUTO_INCLEMENTO_OFF VARCHAR(MAX)      
      
      
      
SELECT       
@AUX_SCRIPT = LINHA      
,@AUTO_INCLEMENTO_ON =  CASE WHEN tem_identity  =  's' then ''''+ 'set identity_insert ' + nome_tab + ' on '  + ''''   else ''''+ '------'+ '''' end      
,@AUTO_INCLEMENTO_OFF =  CASE WHEN tem_identity =  's' then ''''+ 'set identity_insert ' + nome_tab + ' off ' + ''''  else '''' + '------'  + '''' end      
FROM #aux_insert_tab_cols WHERE nome_tab =  @nome_tabela      
      
      
      
IF OBJECT_ID('TEMPDB..#aux_base_fonte') IS NOT NULL      
BEGIN      
drop table #aux_base_fonte                        
END      
      
                         
select  b.name as nome_tabela, a.name as nome_coluna, d.DATA_TYPE as tipo_col,                            
tamanho_col = case when DATA_TYPE in('int','bigint','date','datetime','smalldatetime','FLOAT') then '0'                             
when DATA_TYPE in('char','varchar','nchar','ntext','nvarchar','xml') then convert(varchar(10),CHARACTER_MAXIMUM_LENGTH)                            
when DATA_TYPE in('numeric') then  convert(varchar(10),NUMERIC_PRECISION )+','+ convert(varchar(10),NUMERIC_SCALE) end                            
,identiti =  case when a.is_identity =  1 then  'S' else 'N'end                             
,aceita_nul  =case when a.is_nullable =  1 then 's' else 'n' end                            
,id = column_id                         
,linha = cast(null as varchar(MAX)   )      
,AUX_001 =   cast(null as varchar(MAX)   )      
,AUX_002 =   cast(null as varchar(MAX)   )      
,AUX_0003 =  cast(null as varchar(MAX)   )      
,AUX_0004 =  cast(null as varchar(MAX)   )      
,aux_0005 =  cast(null as varchar(MAX)   )      
,aux_0006 =  cast(null as varchar(MAX)   )      
into #aux_base_fonte                            
from sys.columns  a                             
inner join sys.tables b                            
on a.object_id =  b.object_id                            
inner join INFORMATION_SCHEMA.COLUMNS d                            
on b.name =  d.TABLE_NAME                            
and a.name =  d.COLUMN_NAME                            
where b.type =  'U'                            
AND b.name  = @nome_tabela      
order by a.column_id asc                            
      
      
UPDATE A      
SET       
AUX_0003 = '['+ nome_coluna + '] '                          
 + ' '                                                                  
 + ' VARCHAR (MAX) '                     
 + '  NULL '        
 FROM #aux_base_fonte A       
                            if OBJECT_ID('tempdb..#aux_id') is not null                            
begin                            
drop table #aux_id                            
end                            
                            
                                              
      
 update  a                            
 set a.tamanho_col = case when  tamanho_col =  '-1'  then 'max' else '' end                            
 --select *                             
 from  #aux_base_fonte a                             
 where tamanho_col in ('-1' ,'null')          
                
 UPDATE A      
 SET linha = 'declare ' + '@' + nome_coluna   +  ' ' + case when tipo_col in ('smalldatetime') then tipo_col else  ' varchar(MAX) ' end      
 ,AUX_001 =  ',' + '@' + nome_coluna + ' = ' + nome_coluna      
  from  #aux_base_fonte a            
      
      
        
  UPDATE A      
  SET AUX_001  = '@' + nome_coluna + ' = ' + nome_coluna      
  --SELECT *      
   FROM #aux_base_fonte  A WHERE ID IN (SELECT MIN(ID) FROM #aux_base_fonte                 )      
      
      
      
   update a      
   set      
   AUX_002 =  ',' + '@' + nome_coluna       
  from  #aux_base_fonte a            
      
        
  UPDATE A      
  SET AUX_002  = '@' + nome_coluna       
  --SELECT *      
   FROM #aux_base_fonte  A WHERE ID IN (SELECT MIN(ID) FROM #aux_base_fonte                 )      
      
      
      
      
   update a      
   set      
    AUX_0004 =  CASE WHEN tipo_col = 'NUMERIC' THEN  ''''+'CAST(' + '''' + '+'+'@'+nome_coluna  +'+ '+ ''''+ ' AS ' +' NUMERIC ' + '(' + tamanho_col+ '))'+''''      
   WHEN  tipo_col IN('char','varchar','nchar','ntext','nvarchar','xml') THEN ''''+'N'+''''+' + '+ ''''''''''+ ' + '+ 'REPLACE('+'@'+nome_coluna+','+''''''''''+','+''''''''''''''+ ')' + ' + '+''''''''''      
   WHEN  tipo_col IN('date','datetime' ) THEN ''''+'CAST(N'+''''+'+'+'''''''''' + '+'+'@'+nome_coluna+ '+' +''''''''''+ '+' +''''+ ' AS '   +  tipo_col+ ')' +''''         
   WHEN  tipo_col IN('smalldatetime' ) THEN ''''+'CAST(N'+''''+'+'+'''''''''' + '+'+ 'LEFT(CONVERT(VARCHAR(30),'+'@'+nome_coluna+ ',121)'+',10)' + '+' +''''+'T'+'''' +'+' +'right(CONVERT(VARCHAR(30),'+'@'+nome_coluna+',121)'+',12)'+'+' + '''''''' +''''+ 
'
      +'+''''+ ' AS '   +  tipo_col+ ')' +''''       
   else  '@'+nome_coluna END      
   FROM #aux_base_fonte a       
      
     UPDATE A      
   SET AUX_0004 = 'isnull('+AUX_0004+','+ '''NULL'''+')'      
   FROM  #aux_base_fonte A      
        
      
   update a       
   set       
   AUX_0004 = ' + '+''' , '''+ ' + ' + AUX_0004      
   from #aux_base_fonte A      
   WHERE id <> 1      
      
      
   update  a      
   set a.aux_0005 = case when id <> 1 then   ','  +  'a.'+a.nome_coluna else 'a.'+a.nome_coluna end       
   --select *       
   from #aux_base_fonte a      
      
      
                            
      
 UPDATE A      
 SET aux_0006 = 'declare ' + '@' + nome_coluna+'cursor'   +  ' ' + case when tipo_col in ('char','varchar','nvarchar','numeric') then tipo_col+'('+tamanho_col+')'      
 else tipo_col end      
  from  #aux_base_fonte a            
      
        
      
   IF OBJECT_ID('TEMPDB..#aux_base_fonte_001') IS NOT NULL      
   BEGIN      
   DROP TABLE #aux_base_fonte_001      
   END      
  SELECT * ,id_aux =  identity(int) INTO  #aux_base_fonte_001  FROM #aux_base_fonte      
  ORDER BY id      
       
      
      
      
      
      
  ------------------- Laço para montar o script dinamico de declaração de variaveis, criação do cursor dinamico, tratamento de dados para insert e  auxiliar de criação de coluna      
      
      
   DECLARE       
   @SQL                  VARCHAR(MAX)     = ''   --      
  ,@CONT                      INT              =  1   --Contador do loop      
  ,@QTD_TAB                   INT        -- Contador de tamanho de registros da tabela auxiliar :  #aux_base_fonte_001      
  ,@AUX_LINHA                 VARCHAR(MAX)    --      
  ,@AUX_DECLARE               VARCHAR(MAX)    --Geração de variaveis dinamicamente       
  ,@SQL_VAR       VARCHAR(MAX)      = ''   --      
  ,@SQL_select                VARCHAR(MAX)      = ''   --auxiliar criar select que insere os dados nas variaveis para tratamento de dadlos      
  ,@SQL_select_002            VARCHAR(MAX)      = ''   --auxiliar criar select que insere os dados nas variaveis para tratamento de dadlos      
  ,@AUX_var_002               VARCHAR(MAX)      = ''   --Auxiliar para criar tabs dinamicas      
  ,@SQL_select_001            VARCHAR(MAX)      = ''   --Auxiliar para  mostra um gride do select       
  ,@SQL_CRIAR_TEMP            NVARCHAR(MAX)     = ''  --auxiliar criar temp global      
  ,@SQL_CRIAR_TEMP_002        NVARCHAR(MAX)     = ''  --auxiliar criar temp global      
  ,@SQL_CRIAR_TEMP_inicia     NVARCHAR(max)     = ''  --auxiliar criar temp global      
  ,@aux_select_cursor         nvarchar(max)     = '' -- auxiliar para montar o select do cursor      
  ,@aux_select_cursor_002     nvarchar(max)     = '' -- auxiliar para montar o select do cursor      
  ,@aux_declar_var_cursor     nvarchar(max)     = ''       
  ,@aux_declar_var_cursor_002 nvarchar(max)     = ''       
  ,@aux_variaveis_cursor      nvarchar(max)     = ''       
  ,@aux_variaveis_cursor_002  nvarchar(max)     = ''       
      
  SELECT  @QTD_TAB=  COUNT('')FROM #aux_base_fonte_001      
      
  WHILE @CONT <= @QTD_TAB      
  BEGIN      
      
  SELECT @AUX_LINHA= AUX_001      
  , @AUX_DECLARE =  linha      
  , @AUX_var_002 = AUX_0004      
  , @SQL_CRIAR_TEMP_inicia =  AUX_0003       
  ,@aux_select_cursor_002   = aux_0005      
  ,@aux_declar_var_cursor_002 = aux_0006      
  ,@aux_variaveis_cursor_002  = AUX_002      
  FROM #aux_base_fonte_001  WHERE id_aux = @CONT      
  ORDER BY id ASC      
      
  set @aux_variaveis_cursor += ' ' +  @aux_variaveis_cursor_002      
  set @aux_declar_var_cursor += ' ' + @aux_declar_var_cursor_002      
  set @aux_select_cursor +=  ' ' +  @aux_select_cursor_002       
  SET @SQL +=  @AUX_LINHA + '  '      
  SET @SQL_VAR += @AUX_DECLARE + '  '      
  set @SQL_select_001 +=  @AUX_var_002 + ' '      
  SET @SQL_CRIAR_TEMP += @SQL_CRIAR_TEMP_inicia + ' , '       
       
  DELETE FROM  #aux_base_fonte_001 WHERE id_aux =  @CONT      
  SET @CONT+= 1      
  END      
      
      
      
  declare @cursor_dinamico nvarchar(max)      
      
  set @cursor_dinamico  =  @SQL_VAR + space(3) +      
                                
 'CREATE TABLE #ARQUIVO_SAIDA_TXT (   SEQ_LINHA INT identity, sequencial int ,LINHA VARCHAR(8000))   '  
 +  
 'declare INSERE_TEMP_GLOBAL cursor       
   for select distinct '  +  @aux_select_cursor + SPACE(1) + ' from '      
   + @nome_tabela + ' a '  + char(13)      
   + @STRING  
   + ' open INSERE_TEMP_GLOBAL ' + char(13)       
   + ' fetch  next  from INSERE_TEMP_GLOBAL  into ' + char(13)      
    +@aux_variaveis_cursor + char(13)   
 +' insert into #ARQUIVO_SAIDA_TXT (linha) '     
  + 'select ' + @AUTO_INCLEMENTO_ON      
    + '  while @@FETCH_STATUS = 0  '  + char(13)      
 +'BEGIN ' + char(13)  
  +' insert into #ARQUIVO_SAIDA_TXT (linha) '       
 + 'select ' + @AUX_SCRIPT + ''''+ '('+'''' + '+'+ ' ' + @SQL_select_001  + '+'+  ''''+ ')'+ ''''      
 + ' fetch  next  from INSERE_TEMP_GLOBAL  into ' + char(13)      
    +@aux_variaveis_cursor + char(13)      
 + ' END '      
 + ' close  INSERE_TEMP_GLOBAL '      
 + 'deallocate  INSERE_TEMP_GLOBAL '    
  +' insert into #ARQUIVO_SAIDA_TXT (linha) '     
  + 'select ' + @AUTO_INCLEMENTO_OFF      
  + 'update #ARQUIVO_SAIDA_TXT set sequencial =  SEQ_LINHA '  
  +' exec GERAR_ARQUIVO_TXT_OLEAUTOMATION_SPS ' + '''arquivo_teste'''  
 exec (@cursor_dinamico)      
      
      
end
