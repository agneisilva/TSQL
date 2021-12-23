
CREATE proc  gerar_script_procs_ini  
@nome_procs nvarchar(770)  
as  
begin  
declare @sql_batch_001 nvarchar(max)   
,@cont int = 1 
,@qtd_tab int
, @nome_proc nvarchar(770)
create table #aux_select (
id int identity, 
[text] nvarchar(max))
  
              
                     
declare @objs varchar(8000)                              
if @nome_procs is not null        
begin        
select @objs = 'select name, id from sys.sysobjects where name in(''' + REPLACE(replace(replace(@nome_procs,' ',''),' ',''), ',',''',''')  + ''') order by id'                             
end        
else         
                     
set @objs =  'select name, id =  object_id from sys.procedures where  type = '+ '''p'''        
        
        
create table #table (name varchar(256), id int)                              
insert into #table  exec (@objs)        
 
 IF OBJECT_ID('TEMPDB..#AUX_LACO') IS NOT NULL
 BEGIN
 DROP TABLE #aux_laco
 END
 select *, id_aux = identity(int) into #aux_laco from #table 


  set @qtd_tab =  (select count('') from #aux_laco)

  while @cont <= @qtd_tab 
  begin
  select @nome_proc = name from   #aux_laco where id_aux =  @cont

  set  @sql_batch_001 =  'insert into #aux_select '+char(13) +' exec gerar_script_procs ' + @nome_proc
  exec (@sql_batch_001)
  insert into #aux_select (text) values ('GO')
  delete from  #aux_laco where id_aux =  @cont
  set @cont +=1
  

  end

  select text from #aux_select  order by id 

  
end  

