USE [Viewpoint]

GO

--Step 1

select * into MCKWOCloseStage_032519_BAK from [dbo].MCKWOCloseStage

-- SELECT * FROM dbo.MCKWOCloseStage

--Step 2
BEGIN TRANSACTION


Drop TABLE [dbo].[MCKWOCloseStage]
GO

--Step 3
CREATE TABLE [dbo].[MCKWOCloseStage](
	[Co] bCompany NULL, -- float to bCompany
	[WO] INT NULL,		--  VARCHAR to INT
	[CloseStatus] [VARCHAR](20) NULL, -- 30 to 20 
	[BatchNum] [VARCHAR](30) NULL,
	[BatchMth] bMonth NULL,
	[Creationdate] [DATETIME] NULL DEFAULT (GETDATE()),
	[Createdby] [VARCHAR](30) NULL  DEFAULT (SUSER_SNAME()),
	[ErrorMsg] [VARCHAR](255) NULL -- EXTENDING 30 to 255
) ON [PRIMARY]

GO


--step 4 

--Check SET IDENTITY_INSERT OFF
-- to avoid 'insert into' error-> 'Cannot insert explicit value for identity column in table 'ProphecyLog' when IDENTITY_INSERT is set to OFF.'
-- turn it ON
--SET IDENTITY_INSERT [dbo].[MCKWOCloseStage] ON;  
--GO 

Insert into [dbo].[MCKWOCloseStage]
(	
	[Co] ,
	[WO] ,	
	[CloseStatus] ,
	[BatchNum] ,
	[BatchMth],
	[Creationdate] ,
	[Createdby] ,
	[ErrorMsg] 
) 
Select 
	[Co],
	[WO] ,	
	[CloseStatus] ,
	[BatchNum] ,
	[BatchMth],
	[Creationdate] ,
	[Createdby] ,
	[Status]  From MCKWOCloseStage_032519_BAK

GO


--SET IDENTITY_INSERT [mers].[ProphecyLog] OFF;  
--GO 

Drop table MCKWOCloseStage_032519_BAK
Go

COMMIT