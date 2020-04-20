CREATE TABLE [dbo].[bPMUT]
(
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NOT NULL,
[ImportRoutine] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Override] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_Override] DEFAULT ('N'),
[StdTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[FileType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[Delimiter] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[OtherDelim] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[TextQualifier] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[ItemOption] [char] (1) COLLATE Latin1_General_BIN NULL,
[AccumCosts] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_AccumCosts] DEFAULT ('N'),
[ContractItem] [dbo].[bContractItem] NULL,
[ItemDescription] [dbo].[bItemDesc] NULL,
[BegPosition] [tinyint] NULL,
[EndPosition] [tinyint] NULL,
[ImportSICode] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_ImportSICode] DEFAULT ('N'),
[InitSICode] [char] (1) COLLATE Latin1_General_BIN NULL,
[DefaultSIRegion] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[LastPartPhase] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CreatePhase] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CreateCostType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CreateVendor] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CreateMatl] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CreateUM] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[DefaultContract] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_DefaultContract] DEFAULT ('Y'),
[DefaultFirm] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_DefaultFirm] DEFAULT ('N'),
[COItem] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_COItem] DEFAULT ('N'),
[CreateSICode] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CreateSubRecsYN] [dbo].[bYN] NULL,
[FixedAmt] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_FixedAmt] DEFAULT ('N'),
[DropMatlCode] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_DropMatlCode] DEFAULT ('N'),
[UseSICodeDesc] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_UseSICodeDesc] DEFAULT ('N'),
[RollupMatlCode] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_RollupMatlCode] DEFAULT ('N'),
[UseItemQtyUM] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_UseItemQtyUM] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[IncrementBy] [smallint] NOT NULL CONSTRAINT [DF_bPMUT_IncrementBy] DEFAULT ((0)),
[UserRoutine] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[RecordTypeCol] [int] NULL,
[BegRecTypePos] [int] NULL,
[EndRecTypePos] [int] NULL,
[XMLRowTag] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SampleFile] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UsePhaseUM] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_UsePhaseUM] DEFAULT ('N'),
[MatlImportOption] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMUT_MatlImportOption] DEFAULT ('N'),
[DeptOvr] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_DeptOvr] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UsePhaseDesc] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_UsePhaseDesc] DEFAULT ('N'),
[Copy] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUT_Copy] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMUTi    Script Date: 8/28/99 9:38:03 AM ******/
CREATE trigger [dbo].[btPMUTi] on [dbo].[bPMUT] for INSERT as

/*--------------------------------------------------------------
 * Insert trigger for PMUT 
 * Created By:	GF 06/03/99
 * Modified By:	GF 08/21/2007 - added initialize for import routines
 *				GP 02/03/2009 - 126939, added insert for import template detail.
 &				GP 05/13/2009 - 133427 only insert defaults when copy is not in progress
 *				JayR 03/28/2012 - TK-00000 Switch to using FKs for validation
 *
 *--------------------------------------------------------------*/
declare @errmsg varchar(255), @Template varchar(10), @Description bDesc, 
	@Copy bYN, @rcode int

if @@rowcount = 0 return
set nocount on 

---- execute SP to load standard import routines
exec @rcode = dbo.bspPMUIInitialize 'StdLoad', @errmsg output

---- execute SP to load import template detail, issue 126939.
select @Template = i.Template, @Description = i.Description, @Copy = i.Copy from inserted i

if @Copy = 'N' --133427
begin
	exec @rcode = dbo.vspPMImportPMUDDefault @Template, @Description, @errmsg output
end

RETURN 







GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_AccumCosts] CHECK (([AccumCosts]='Y' OR [AccumCosts]='N'))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_COItem] CHECK (([COItem]='Y' OR [COItem]='N'))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_CreateSubRecsYN] CHECK (([CreateSubRecsYN]='Y' OR [CreateSubRecsYN]='N' OR [CreateSubRecsYN] IS NULL))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_DefaultContract] CHECK (([DefaultContract]='Y' OR [DefaultContract]='N'))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_DefaultFirm] CHECK (([DefaultFirm]='Y' OR [DefaultFirm]='N'))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_DropMatlCode] CHECK (([DropMatlCode]='Y' OR [DropMatlCode]='N'))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_FixedAmt] CHECK (([FixedAmt]='Y' OR [FixedAmt]='N'))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_ImportSICode] CHECK (([ImportSICode]='Y' OR [ImportSICode]='N'))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_Override] CHECK (([Override]='Y' OR [Override]='N'))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_RollupMatlCode] CHECK (([RollupMatlCode]='Y' OR [RollupMatlCode]='N'))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_UseItemQtyUM] CHECK (([UseItemQtyUM]='Y' OR [UseItemQtyUM]='N'))
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [CK_bPMUT_UseSICodeDesc] CHECK (([UseSICodeDesc]='Y' OR [UseSICodeDesc]='N'))
GO
ALTER TABLE [dbo].[bPMUT] ADD CONSTRAINT [PK_bPMUT] PRIMARY KEY CLUSTERED  ([Template]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMUT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMUT] WITH NOCHECK ADD CONSTRAINT [FK_bPMUT_bPMUI] FOREIGN KEY ([ImportRoutine]) REFERENCES [dbo].[bPMUI] ([ImportRoutine])
GO
ALTER TABLE [dbo].[bPMUT] NOCHECK CONSTRAINT [FK_bPMUT_bPMUI]
GO