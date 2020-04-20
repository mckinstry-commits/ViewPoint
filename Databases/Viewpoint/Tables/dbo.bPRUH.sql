CREATE TABLE [dbo].[bPRUH]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[Quarter] [dbo].[bMonth] NOT NULL,
[EIN] [char] (9) COLLATE Latin1_General_BIN NOT NULL,
[CoName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (25) COLLATE Latin1_General_BIN NULL,
[CoState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[ZipExt] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[Contact] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Phone] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[PhoneExt] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[TransId] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[C3] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[SuffixCode] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[TotalRemit] [dbo].[bDollar] NOT NULL,
[CreateDate] [dbo].[bDate] NULL,
[Computer] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[EstabId] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[StateId] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[UnempID] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[TaxType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[TaxEntity] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ControlId] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[UnitId] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[OtherEIN] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[TaxRate] [dbo].[bRate] NOT NULL,
[PrevUnderPay] [dbo].[bDollar] NOT NULL,
[Interest] [dbo].[bDollar] NOT NULL,
[Penalty] [dbo].[bDollar] NOT NULL,
[OverPay] [dbo].[bDollar] NOT NULL,
[AssesRate1] [dbo].[bRate] NOT NULL,
[AssesAmt1] [dbo].[bDollar] NOT NULL,
[AssessRate2] [dbo].[bRate] NOT NULL,
[AssessAmt2] [dbo].[bDollar] NOT NULL,
[TotalDue] [dbo].[bDollar] NOT NULL,
[AllocAmt] [dbo].[bDollar] NOT NULL,
[County] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[OutCounty] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[DocControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[MultiCounty] [tinyint] NULL,
[MultiLocation] [tinyint] NULL,
[MultiIndicator] [tinyint] NULL,
[ElectFundTrans] [tinyint] NULL,
[FilingType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPRUH_FilingType] DEFAULT ('O'),
[LocAddress] [varchar] (22) COLLATE Latin1_General_BIN NULL,
[Plant] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[Branch] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Penalty2] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRUH_Penalty2] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[EMail] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[FTECount] [int] NULL,
[FTEAmtDue] [dbo].[bDollar] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRUH] ON [dbo].[bPRUH] ([PRCo], [State], [Quarter]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRUH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPRUHd    Script Date: 8/28/99 9:38:12 AM ******/
   CREATE  trigger [dbo].[btPRUHd] on [dbo].[bPRUH] for DELETE as
    

/*-----------------------------------------------------------------
     *	Created by: df 12/9/99
     *	Modified:	EN 02/20/03 - issue 23061  added isnull check, and dbo
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int
    declare @prco integer, @state varchar(4), @quarter bMonth
   
    select @numrows = @@rowcount
   
    if @numrows = 0 return
   
    SELECT @prco = deleted.PRCo, @state = deleted.State, @quarter = deleted.Quarter from deleted
    DELETE FROM dbo.PRUE where PRCo = @prco and State= @state and Quarter = @quarter
   
    if @@error <> 0
       goto error
   
    set nocount on
   
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Unemployment Header!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
   
   
   
  
 



GO
