CREATE PROC EXECUCAO_SCRIPT_SPS
(
     @ANO_MES    	  VARCHAR(6)
	,@COD_SEGURADORA  VARCHAR(6)
	,@USUARIO         VARCHAR(60)
)
AS
--------------------------------------------------------------------------------------------------------------------
-- SELECIONA SCRITP PARA EXECUÇÃO VIA TAREFA AUTOMÁTICA
-- SELECIONA DE ACORDO COM A PRIORIDADE E DATE DE ENTRADA
/* 
   PRIORIDADE  
		0 - URGENTE 
		1 - ALTA 
		2 - NORMAL 
		3 - BAIXA 

*/
--------------------------------------------------------------------------------------------------------------------
BEGIN
      
	  SET NOCOUNT ON

	  DECLARE @SCRIPT             VARCHAR(MAX) = ''
	  DECLARE @LINHAS_AFETADAS    INT
	  DECLARE @EXECUCAO_SCRIPT_ID INT
      DECLARE @DT_INICIO_EXEC     DATETIME 
	  DECLARE @DT_FIM_EXEC        DATETIME 

	  SELECT   TOP 1 
	           @EXECUCAO_SCRIPT_ID = EXECUCAO_SCRIPT_ID
	          ,@SCRIPT = ISNULL(SCRIPT,'')
	  FROM     EXECUCAO_SCRIPT_TB WITH( NOWAIT, NOLOCK )
	  WHERE    EXECUTADO = 'N'
	  AND      PRIORIDADE IN ( 0, 1 , 2, 3 )	
	  ORDER BY PRIORIDADE 
	         , DT_INCLUSAO
      
	  -- ABORTA 
	  IF @EXECUCAO_SCRIPT_ID IS NULL 
	     RETURN

	  -- RECUPERA DATA DE INÍCIO DE EXECUÇÃO
	  SELECT @DT_INICIO_EXEC = GETDATE()

	  BEGIN TRY

	         IF LEN(@SCRIPT) = 0
	            RAISERROR ( ' Script Inválido ' ,16, 1 )

	        -- EXECUTA O COMANDO
	        EXECUTE (@SCRIPT)
			
			-- RECUPERA LINHAS AFETADAS( SE HOUVER )
			SET @LINHAS_AFETADAS = @@ROWCOUNT
           
    	    -- RECUPERA DATA DE FIM DE EXECUÇÃO
		    SELECT @DT_FIM_EXEC = GETDATE()

			-- ALTERA O STATUS DA EXECUÇÃO COM SUCESSO
			UPDATE EX
			SET    EX.EXECUTADO         = 'S'
			      ,EX.EXECUTADO_SUCESSO = 'S'
                  ,DT_ALTERACAO         = GETDATE()
				  ,DT_INICIO_EXEC       = @DT_INICIO_EXEC
				  ,DT_FIM_EXEC          = @DT_FIM_EXEC
				  ,LOG_EXECUCAO         = 'Script executado com sucesso' + CASE WHEN @LINHAS_AFETADAS <> 0 
				                                                                  THEN ' | Linhas afetadas = ' + CAST(@LINHAS_AFETADAS AS VARCHAR(50))
				                                                                  ELSE ''
																				  END
			FROM   EXECUCAO_SCRIPT_TB EX
			WHERE  EXECUCAO_SCRIPT_ID = @EXECUCAO_SCRIPT_ID

      END TRY
	  BEGIN CATCH
	        
			-- RECUPERA DATA DE FIM DE EXECUÇÃO
			SELECT @DT_FIM_EXEC = GETDATE()
			
			-- ALTERA O STATUS DA EXECUÇÃO COM ERRO
	        UPDATE EX
			SET    EX.EXECUTADO         = 'S'
			      ,EX.EXECUTADO_SUCESSO = 'N'
                  ,DT_ALTERACAO         = GETDATE()		
				  ,DT_INICIO_EXEC       = @DT_INICIO_EXEC
				  ,DT_FIM_EXEC          = @DT_FIM_EXEC
				  ,LOG_EXECUCAO         = 'Script não pôde ser executado: ' +
				                          'Erro  - ' + ERROR_MESSAGE() +			  
										  'Linha - ' + CAST(ERROR_LINE() AS VARCHAR(10))
			FROM   EXECUCAO_SCRIPT_TB EX
			WHERE  EXECUCAO_SCRIPT_ID = @EXECUCAO_SCRIPT_ID

	  END CATCH

END

