CREATE procedure gerar_script_procs_v2            
@nome_procs nvarchar(770)       
  
as              
/*  
Autor: Leandro Sampaio  
  
*/      
      
declare @sql_batch_001 nvarchar(max)           
,@cont int = 1         
,@qtd_tab int        
, @nome_proc nvarchar(770)        
,@objname nvarchar(776)        
,@columnname nvarchar(770) =  null      
      
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
      
  set @objname =  @nome_proc       
            
              
set nocount on              
              
declare @dbname sysname              
,@objid int              
,@BlankSpaceAdded   int              
,@BasePos       int              
,@CurrentPos    int              
,@TextLength    int              
,@LineId        int              
,@AddOnLen      int              
,@LFCR          int   
,@DefinedLength int              
,@SyscomText nvarchar(max)              
,@Line          nvarchar(max)              
              
select @DefinedLength = 1000             
select @BlankSpaceAdded = 0   

IF OBJECT_ID('TEMPDB..#CommentText') IS NOT NULL
BEGIN
  DROP TABLE #CommentText
  END
CREATE TABLE #CommentText              
(LineId int              
 ,Text  nvarchar(1000) collate catalog_default)              
           
select @dbname = parsename(@objname,3)              
if @dbname is null              
 select @dbname = db_name()              
else if @dbname <> db_name()              
        begin              
                raiserror(15250,-1,-1)              
                return (1)              
        end              
              
             
select @objid = object_id(@objname)              
if (@objid is null)              
        begin              
  raiserror(15009,-1,-1,@objname,@dbname)              
  return (1)              
        end              
              
           
if ( @columnname is not null)              
    begin              
          
        if (select count(*) from sys.objects where object_id = @objid and type in ('S ','U ','TF'))=0              
            begin              
                raiserror(15218,-1,-1,@objname)              
                return(1)              
            end              
          
        if ((select 'count'=count(*) from sys.columns where name = @columnname and object_id = @objid) =0)              
            begin              
                raiserror(15645,-1,-1,@columnname)              
                return(1)              
    end              
    if (ColumnProperty(@objid, @columnname, 'IsComputed') = 0)              
  begin              
   raiserror(15646,-1,-1,@columnname)              
   return(1)              
  end              
              
        declare ms_crs_syscom  CURSOR LOCAL              
        FOR select text from syscomments where id = @objid and encrypted = 0 and number =              
                        (select column_id from sys.columns where name = @columnname and object_id = @objid)              
                        order by number,colid              
        FOR READ ONLY              
              
    end              
else if @objid < 0   
 begin              
    
  if (select count(*) from master.sys.syscomments where id = @objid and text is not null) = 0              
   begin              
    raiserror(15197,-1,-1,@objname)              
    return (1)              
   end              
                 
  declare ms_crs_syscom CURSOR LOCAL FOR select text from master.sys.syscomments where id = @objid              
   ORDER BY number, colid FOR READ ONLY              
 end              
else              
    begin              
         
                 
         
         
        if (select count(*) from syscomments c, sysobjects o where o.xtype not in ('S', 'U')              
            and o.id = c.id and o.id = @objid) = 0              
                begin              
                        raiserror(15197,-1,-1,@objname)              
                        return (1)              
                end              
              
        if (select count(*) from syscomments where id = @objid and encrypted = 0) = 0              
                begin              
                        raiserror(15471,-1,-1,@objname)              
                        return (0)              
                end              
              
  declare ms_crs_syscom  CURSOR LOCAL              
  FOR select text from syscomments where id = @objid and encrypted = 0              
    ORDER BY number, colid              
  FOR READ ONLY              
              
    end              
              
  
           
  
select @LFCR = 2              
select @LineId = 1              
              
              
OPEN ms_crs_syscom              
              
FETCH NEXT from ms_crs_syscom into @SyscomText              
              
WHILE @@fetch_status >= 0              
begin              
              
    select  @BasePos    = 1              
 select  @CurrentPos = 1              
    select  @TextLength = LEN(@SyscomText)              
              
    WHILE @CurrentPos  != 0              
    begin              
       
        select @CurrentPos =   CHARINDEX(char(13)+char(10), @SyscomText, @BasePos)              
              
       
        IF @CurrentPos != 0              
        begin              
             
            
       
       
            while (isnull(LEN(@Line),0) + @BlankSpaceAdded + @CurrentPos-@BasePos + @LFCR) > @DefinedLength              
            begin              
                select @AddOnLen = @DefinedLength-(isnull(LEN(@Line),0) + @BlankSpaceAdded)              
                INSERT #CommentText VALUES              
                ( @LineId,              
                  isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @AddOnLen), N''))              
                select @Line = NULL, @LineId = @LineId + 1,      
                       @BasePos = @BasePos + @AddOnLen, @BlankSpaceAdded = 0              
            end              
            select @Line    = isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @CurrentPos-@BasePos + @LFCR), N'')              
            select @BasePos = @CurrentPos+2              
            INSERT #CommentText VALUES( @LineId, @Line )              
            select @LineId = @LineId + 1              
            select @Line = NULL              
        end              
        else              
        
        begin              
            IF @BasePos <= @TextLength   
            begin              
        
        
        
                while (isnull(LEN(@Line),0) + @BlankSpaceAdded + @TextLength-@BasePos+1 ) > @DefinedLength              
                begin              
                    select @AddOnLen = @DefinedLength - (isnull(LEN(@Line),0) + @BlankSpaceAdded)              
                    INSERT #CommentText VALUES              
                    ( @LineId,              
                      isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @AddOnLen), N''))              
                    select @Line = NULL, @LineId = @LineId + 1,              
                        @BasePos = @BasePos + @AddOnLen, @BlankSpaceAdded = 0              
                end              
                select @Line = isnull(@Line, N'') + isnull(SUBSTRING(@SyscomText, @BasePos, @TextLength-@BasePos+1 ), N'')              
                if LEN(@Line) < @DefinedLength and charindex(' ', @SyscomText, @TextLength+1 ) > 0              
                begin              
                    select @Line = @Line + ' ', @BlankSpaceAdded = 1              
                end              
            end              
        end              
    end              
              
 FETCH NEXT from ms_crs_syscom into @SyscomText              
end              
              
IF @Line is NOT NULL              
    INSERT #CommentText VALUES( @LineId, @Line )              
 insert into  #CommentText (LineId,Text)            
 select -1, 'if exists (select top 1 1 from sys.procedures where name ='+''''+@objname+''''+' ) begin drop procedure ' + @objname  + ' END '            
 insert into  #CommentText (LineId,Text)            
 select 0, 'GO '             
             
            
  
insert into #aux_select (text)      
select Text from #CommentText order by LineId        
      
insert into #aux_select (text) values (' GO ')      
      
      
              
CLOSE  ms_crs_syscom              
DEALLOCATE  ms_crs_syscom              
           
		   set @LineId = null
		   set @Line = null

DROP TABLE  #CommentText              
      
set @cont +=1      
           
end      
select text from #aux_select      
order by id 
