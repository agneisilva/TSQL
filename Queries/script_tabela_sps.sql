          
CREATE procedure dbo.script_tabela_sps                 
@tabela varchar(500)  ,@exec int = 0                
as                  
set nocount on                
                
declare @objs nvarchar(max)                  
select @objs = 'select name, id from sys.sysobjects where name in(''' + REPLACE(replace(replace(@tabela,' ',''),' ',''), ',',''',''')  + ''') order by id'                 
                  
create table #table (name varchar(256), id int)                  
insert into #table  exec (@objs)                  
                  
create table #script (id int identity, sql nvarchar(max))                  
create table #script_alter (id int identity, sql nvarchar(max))                  
create table #script_create (id int identity, sql nvarchar(max))                  
declare @nome_tabela varchar(256)                  
declare @nome_coluna varchar(256)                  
declare @id bigint                   
declare @IS_NULLABLE as varchar(5)                  
declare @DATA_TYPE as varchar(256)                  
declare @CHARACTER_MAXIMUM_LENGTH as varchar(10)                   
declare @CHARACTER_OCTET_LENGTH as varchar(10)                  
declare @NUMERIC_PRECISION as varchar(10)                  
declare @NUMERIC_SCALE as varchar(10)                  
declare @ORDINAL_POSITION int                   
declare @sql nvarchar(max)                  
declare @identity nvarchar(max)                 
declare @null varchar(500)                 
              
                  
while exists (select top 1 * from #table)                  
begin                  
 select @nome_tabela  = name, @id = id from #table   order by id                 
                  
 insert into #script_create(sql) select ' create table ' + @nome_tabela + '('                  
                  
 select * into #colunas from INFORMATION_SCHEMA.COLUMNS where TABLE_CATALOG = DB_NAME() and TABLE_NAME = @nome_tabela  order by ORDINAL_POSITION                   
 declare @max int                  
 select @max = MAX(ORDINAL_POSITION) from #colunas                  
 while exists (select top 1 * from #colunas)                  
 begin                  
  select top 1                   
  @nome_coluna= COLUMN_NAME,                   
  @IS_NULLABLE = IS_NULLABLE ,                  
  @DATA_TYPE = DATA_TYPE ,                  
  @CHARACTER_MAXIMUM_LENGTH = CHARACTER_MAXIMUM_LENGTH ,                  
  @CHARACTER_OCTET_LENGTH = CHARACTER_OCTET_LENGTH ,                  
  @NUMERIC_PRECISION = NUMERIC_PRECISION ,                  
  @NUMERIC_SCALE = NUMERIC_SCALE,                  
  @ORDINAL_POSITION  = ORDINAL_POSITION               
  from #colunas order by ORDINAL_POSITION                   
  select @identity = ''                
  select @null = ''                
  select @identity = Case When s.Colstat & 1 = 1 Then ' Identity(' + Cast(ident_seed(O.name) as varchar) + ',' + Cast(ident_incr(O.name) as Varchar) + ') ' Else '' End              
     ,@null = Case When s.IsNullable =0 or s.Colstat & 1 = 1 Then ' NOT NULL ' Else ' NULL ' End                   
  from sys.syscolumns s inner join sys.sysobjects o on s.id = o.id and o.name = @nome_tabela and s.name = @nome_coluna                  
                 
                  
  select @sql = @nome_coluna + ' '                  
  if @nome_coluna = 'dt_inclusao'                   
  begin                  
   select @sql = @sql + 'ud_dt_inclusao'                  
  end                  
  else if @nome_coluna = 'dt_alteracao'                   
  begin                  
   select @sql = @sql + 'ud_dt_alteracao'                  
  end                  
  else if @nome_coluna = 'usuario'                   
  begin                  
   select @sql = @sql + 'ud_usuario'                  
  end                  
  else                  
  begin                  
   select @sql = @sql + @DATA_TYPE       
    if @CHARACTER_MAXIMUM_LENGTH is not null                  
    begin                  
   select @sql = @sql + case when @CHARACTER_MAXIMUM_LENGTH = 0 then '' else  '(' + @CHARACTER_MAXIMUM_LENGTH + ')'  end + ' ' + @null + ' ' + @identity                  
   end                  
    else          
    if @NUMERIC_PRECISION  is not null and @DATA_TYPE <> 'int'                  
    begin                  
     select @sql = @sql + '(' + @NUMERIC_PRECISION + ',' + @NUMERIC_SCALE +  ')' +' ' + @null + ' ' + @identity                  
    end                  
    else                  
    begin                  
select @sql = @sql  +' ' + @null + ' ' + @identity                   
    end                   
                      
  end                  
                    
                    
  insert into #script_create(sql) select @sql +  case when @max <> @ORDINAL_POSITION then ',' else ')' end                   
            
  insert into #script_alter (sql) select 'if exists(select top 1  1 from sys.sysobjects o inner join sys.syscolumns s on s.id = o.id and o.name = ''' + @nome_tabela + '''and s.name = ''' + @nome_coluna+ ''')'                  
  insert into #script_alter (sql) select 'begin'                  
                     
   insert into #script_alter select 'if not exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = ''' + @nome_coluna  + ''' and IS_NULLABLE = ''' + @IS_NULLABLE + ''' and DATA_TYPE = ''' + @DATA_TYPE + ''' and                  
   isnull(CHARACTER_MAXIMUM_LENGTH,0) = ' + isnull(@CHARACTER_MAXIMUM_LENGTH, '0') + ' and isnull(CHARACTER_OCTET_LENGTH,0) = ' + isnull(@CHARACTER_OCTET_LENGTH,'0') +               
   ' and isnull(NUMERIC_PRECISION,0) = ' + isnull(@NUMERIC_PRECISION,0) + ' and isnull(NUMERIC_SCALE,0) = ' +ISNULL(@NUMERIC_SCALE,'0') + '              
   and TABLE_NAME = ''' + @nome_tabela + ''' and TABLE_CATALOG=DB_NAME())'                  
              
                 
   insert into #script_alter select 'begin'                  
     if @identity <> ''                   
     begin                  
       if @exec = 1                 
       begin                
   insert into #script_alter select 'alter table '  + @nome_tabela + ' add ' + 'XXX' + @sql                  
   insert into #script_alter select 'Alter Table ' + @nome_tabela  + ' Drop Column ' + @nome_coluna                  
   insert into #script_alter select 'Exec sp_rename ''' + @nome_tabela + '.' + 'XXX' + @nome_coluna + ''', ''' + @nome_coluna + ''',''Column'''                  
  end                
       insert into #script_alter (sql) select ' print ''' + ' alter table '  + @nome_tabela + ' alter column  ' + @sql + ''''                  
     end                  
     else                  
     begin                  
    if @exec = 1                 
       begin                
   insert into #script_alter (sql) select ' alter table '  + @nome_tabela + ' alter column  ' + @sql                  
    end                
      insert into #script_alter (sql) select ' print ''' + ' alter table '  + @nome_tabela + ' alter column  ' + @sql + ''''                  
     end                  
  insert into #script_alter select 'end'                  
  insert into #script_alter (sql) select 'end'                  
  insert into #script_alter (sql) select 'else'                  
  insert into #script_alter (sql) select 'begin'                  
  if @exec = 1                 
  begin                
 insert into #script_alter (sql) select ' alter table '  + @nome_tabela + ' add ' + @sql                  
  end                
  insert into #script_alter (sql) select ' print ''' + ' alter table '  + @nome_tabela + ' add ' + @sql + ''''                  
  insert into #script_alter (sql) select 'end'                  
                    
                    
  delete from #colunas where COLUMN_NAME = @nome_coluna             
 end                  
 drop table #colunas                  
 insert into #script (sql) select 'print '' '' '                
 insert into #script (sql) select 'print '' ------------------------------------ '' '                
 insert into #script (sql) select 'print '' '' '                
 insert into #script (sql) select 'print ''iniciando scripta de criação/alteração da tabela:' + @nome_tabela + ''''                  
 insert into #script (sql) select 'if not exists(select 1 from sys.sysobjects where name = ''' + @nome_tabela + ''')'                  
 insert into #script (sql) select 'begin'                  
 if @exec = 1                 
 begin                
 insert into #script (sql) select sql from #script_create order by id                  
 end                
 insert into #script (sql) select ' print ''' + ' create table '  + @nome_tabela + ''''                  
 insert into #script (sql) select 'end'                  
 insert into #script (sql) select 'else'                  
 insert into #script (sql) select 'begin'                  
 insert into #script (sql) select sql from #script_alter order by id                  
 insert into #script (sql) select 'end'                  
                   
 --create table #indice (nome varchar(256), sql nvarchar(max))                 
 --insert into #indice  exec Script_indice_sps @nome_tabela                  
 -- declare @nome_indice as varchar(256)                  
 -- declare @sql_indice as nvarchar(max)                  
 -- while exists (select 1 from #indice)                  
 -- begin                  
 -- select top 1 @nome_indice  = nome, @sql_indice  = sql from #indice                  
 -- insert into #script (sql) select 'if not exists(select top 1 1 from sys.sysindexes where name = ''' + @nome_indice + ''' union select top 1 1 from sys.sysobjects where name = ''' + @nome_indice + ''')'                  
 -- insert into #script (sql) select 'begin'                
 -- if @exec = 1                 
 -- begin                  
 --insert into #script (sql) select @sql_indice                  
 -- end                
 -- insert into #script (sql) select 'print ''criando indice ' + @nome_indice + ''''                  
 -- insert into #script (sql) select 'end'                  
 -- delete from #indice where nome = @nome_indice                  
 -- end                  
 --drop table #indice                  
                  
 delete from #table where name = @nome_tabela                  
 delete from #script_alter                  
 delete from #script_create                  
end                   
                  
select sql from #script order by id                  
drop table #script                  
drop table #script_alter                  
drop table #script_create                  
drop table #table 

