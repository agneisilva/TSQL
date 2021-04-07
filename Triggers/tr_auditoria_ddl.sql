SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[auditoria_ddl_tb](
	[id_auditoria_ddl] [int] IDENTITY(1,1) NOT NULL,
	[dt_evento] [datetime] NOT NULL,
	[tp_evento] [varchar](50) NULL,
	[des_evento] [varchar](max) NULL,
	[des_evento_xml] [xml] NULL,
	[nm_database] [varchar](125) NULL,
	[nm_schema] [varchar](125) NULL,
	[nm_objeto] [varchar](125) NULL,
	[nm_hostname] [varchar](32) NULL,
	[nm_aplicacao] [varchar](125) NULL,
	[nm_login] [varchar](125) NULL,
 CONSTRAINT [PK_auditoria_ddl] PRIMARY KEY CLUSTERED 
(
	[id_auditoria_ddl] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [SECONDARY]
) ON [SECONDARY] TEXTIMAGE_ON [SECONDARY]
GO

ALTER TABLE [dbo].[auditoria_ddl_tb] ADD  DEFAULT (getdate()) FOR [dt_evento]
GO






-- Trigger auditoria
create TRIGGER [tr_auditoria_ddl]
    ON database
    FOR CREATE_TABLE,ALTER_TABLE,DROP_TABLE,CREATE_VIEW,ALTER_VIEW,DROP_VIEW,CREATE_TRIGGER,ALTER_TRIGGER,DROP_TRIGGER,CREATE_PROCEDURE,ALTER_PROCEDURE,DROP_PROCEDURE,
		CREATE_FUNCTION,ALTER_FUNCTION,DROP_FUNCTION
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE
        @EventData XML = EVENTDATA();    
 
    INSERT dbo.auditoria_ddl_tb
    (
        tp_evento,
        des_evento,
        des_evento_xml,
        nm_database,
        nm_schema,
        nm_objeto,
        nm_hostname,
        nm_aplicacao,
        nm_login
    )
    SELECT
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]',   'NVARCHAR(100)'), 
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'),
        @EventData,
        DB_NAME(),
        @EventData.value('(/EVENT_INSTANCE/SchemaName)[1]',  'NVARCHAR(255)'), 
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)'),
        HOST_NAME(),
        PROGRAM_NAME(),
        SUSER_SNAME();
END
GO

ENABLE TRIGGER [tr_auditoria_ddl] ON DATABASE
GO


