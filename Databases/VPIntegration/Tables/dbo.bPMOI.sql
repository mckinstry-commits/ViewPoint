CREATE TABLE [dbo].[bPMOI]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PCOType] [dbo].[bDocType] NULL,
[PCO] [dbo].[bPCO] NULL,
[PCOItem] [dbo].[bPCOItem] NULL,
[ACO] [dbo].[bACO] NULL,
[ACOItem] [dbo].[bACOItem] NULL,
[Description] [dbo].[bItemDesc] NULL,
[Status] [dbo].[bStatus] NOT NULL,
[ApprovedDate] [dbo].[bDate] NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[PendingAmount] [dbo].[bDollar] NULL,
[ApprovedAmt] [dbo].[bDollar] NULL,
[Issue] [dbo].[bIssue] NULL,
[Date1] [dbo].[bDate] NULL,
[Date2] [dbo].[bDate] NULL,
[Date3] [dbo].[bDate] NULL,
[Contract] [dbo].[bContract] NOT NULL,
[ContractItem] [dbo].[bContractItem] NULL,
[Approved] [dbo].[bYN] NOT NULL,
[ApprovedBy] [dbo].[bVPUserName] NULL,
[ForcePhaseYN] [dbo].[bYN] NOT NULL,
[FixedAmountYN] [dbo].[bYN] NOT NULL,
[FixedAmount] [dbo].[bDollar] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[BillGroup] [dbo].[bBillingGroup] NULL,
[ChangeDays] [smallint] NULL CONSTRAINT [DF_bPMOI_ChangeDays] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[InterfacedDate] [dbo].[bDate] NULL,
[ProjectCopy] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMOI_ProjectCopy] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BudgetNo] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RFIType] [dbo].[bDocType] NULL,
[RFI] [dbo].[bDocument] NULL,
[InterfacedBy] [dbo].[bVPUserName] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMOId    Script Date: 8/28/99 9:37:56 AM ******/
CREATE   TRIGGER [dbo].[btPMOId] ON [dbo].[bPMOI]
    FOR DELETE
AS
    /*--------------------------------------------------------------
 * Delete trigger for PMOI
 * Created By:	JE	08/21/98
 * Modified By:	GF	04/26/2000
 *				TV	04/03/01 - Needs to update PMOH.ChangeDays and JCCM.CurrentDays
 *				GF 11/10/2003 - issue #22944 - JCCM.CurrentDays update
 *				GF 10/13/2004 - issue #25773 need to make sure PCO item being deleted not included in status update check
 *				GF 11/09/2004 - issue #22768 - additional pending status's. Also cleanup trigger cursor
 *				GF 11/26/2006 - 6.x document history
 *				GF 02/05/2007 - issue #123699 issue history
 *				GF 04/30/2008 - issue #22100 revenue addon re-direct. update to PMOA when aco item deleted.
 *				GF 01/26/2011 - tfs #398
 *
 *				 
 *
 *--------------------------------------------------------------*/
    DECLARE @numrows INT ,
        @errmsg VARCHAR(255) ,
        @rcode INT ,
        @validcnt INT ,
        @opencursor TINYINT ,
        @retcode INT ,
        @pending_count INT ,
        @pcoitem_count INT ,
        @appfinal_count INT ,
        @approved_count INT ,
        @pendingstatus TINYINT ,
        @changedays SMALLINT ,
        @pmco bCompany ,
        @project bJob ,
        @pcotype bDocType ,
        @pco bPCO ,
        @aco bACO ,
        @pcoitem bPCOItem ,
        @contract bContract ,
        @currentpendingstatus TINYINT ,
        @revacoitemid BIGINT ,
        @projectcopy bYN

    SELECT  @numrows = @@rowcount
    IF @numrows = 0 
        RETURN
    SET nocount ON

    SELECT  @rcode = 0 ,
            @opencursor = 0

	---- check pending change order
	-- NOTE:  The line ...AND bPMOL.ACO IS NULL... in the JOIN prevents us from changing this to a FK for validation.
    IF NOT EXISTS ( SELECT  *
                    FROM    bPMOL
                            JOIN deleted d ON bPMOL.PMCo = d.PMCo
                                              AND bPMOL.Project = d.Project
                                              AND bPMOL.PCOType = d.PCOType
                                              AND bPMOL.PCO = d.PCO
                                              AND bPMOL.PCOItem = d.PCOItem
                                              AND bPMOL.ACO IS NULL ) 
        BEGIN

            SELECT  @validcnt = COUNT(*)
            FROM    bPMOL
                    JOIN deleted d ON bPMOL.PMCo = d.PMCo
                                      AND bPMOL.Project = d.Project
                                      AND bPMOL.PCOType = d.PCOType
                                      AND bPMOL.PCO = d.PCO
                                      AND bPMOL.PCOItem = d.PCOItem
            IF @validcnt <> 0 
                BEGIN
                    SELECT  @errmsg = 'Pending Change Order Phases exist!'
                    GOTO error
                END


            SELECT  @validcnt = COUNT(*)
            FROM    bPMSL
                    JOIN deleted d ON bPMSL.PMCo = d.PMCo
                                      AND bPMSL.Project = d.Project
                                      AND bPMSL.PCOType = d.PCOType
                                      AND bPMSL.PCO = d.PCO
                                      AND bPMSL.PCOItem = d.PCOItem
            IF @validcnt <> 0 
                BEGIN
                    SELECT  @errmsg = 'Subcontract detail exists for Pending Change Order!'
                    GOTO error
                END

            SELECT  @validcnt = COUNT(*)
            FROM    bPMMF
                    JOIN deleted d ON bPMMF.PMCo = d.PMCo
                                      AND bPMMF.Project = d.Project
                                      AND bPMMF.PCOType = d.PCOType
                                      AND bPMMF.PCO = d.PCO
                                      AND bPMMF.PCOItem = d.PCOItem
            IF @validcnt <> 0 
                BEGIN
                    SELECT  @errmsg = 'Material detail exists for Pending Change Order!'
                    GOTO error
                END
        END


---- check approved change order
    SELECT  @validcnt = COUNT(*)
    FROM    bPMOL
            JOIN deleted d ON bPMOL.PMCo = d.PMCo
                              AND bPMOL.Project = d.Project
                              AND bPMOL.ACO = d.ACO
                              AND bPMOL.ACOItem = d.ACOItem
    IF @validcnt <> 0 
        BEGIN
            SELECT  @errmsg = 'Approved Change Order Phases exist!'
            GOTO error
        END

    SELECT  @validcnt = COUNT(*)
    FROM    bPMSL
            JOIN deleted d ON bPMSL.PMCo = d.PMCo
                              AND bPMSL.Project = d.Project
                              AND bPMSL.ACO = d.ACO
                              AND bPMSL.ACOItem = d.ACOItem
    IF @validcnt <> 0 
        BEGIN
            SELECT  @errmsg = 'Subcontract detail exists for Approved Change Order!'
            GOTO error
        END

    SELECT  @validcnt = COUNT(*)
    FROM    bPMMF
            JOIN deleted d ON bPMMF.PMCo = d.PMCo
                              AND bPMMF.Project = d.Project
                              AND bPMMF.ACO = d.ACO
                              AND bPMMF.ACOItem = d.ACOItem
    IF @validcnt <> 0 
        BEGIN
            SELECT  @errmsg = 'Material detail exists for Approved Change Order!'
            GOTO error
        END
 
---- create cursor on deleted to update pending status and change days
    IF @numrows = 1 
        BEGIN
            SELECT  @pmco = PMCo ,
                    @project = Project ,
                    @pcotype = PCOType ,
                    @pco = PCO ,
                    @pcoitem = PCOItem ,
                    @aco = ACO ,
                    @contract = Contract ,
                    @changedays = ChangeDays ,
                    @revacoitemid = KeyID ,
                    @projectcopy = ProjectCopy
            FROM    deleted
        END
    ELSE 
        BEGIN
            DECLARE bPMOI_delete CURSOR LOCAL FAST_FORWARD
            FOR
                SELECT  PMCo ,
                        Project ,
                        PCOType ,
                        PCO ,
                        PCOItem ,
                        ACO ,
                        Contract ,
                        ChangeDays ,
                        KeyID ,
                        ProjectCopy
                FROM    deleted
   
            OPEN bPMOI_delete
            SET @opencursor = 1
   
            FETCH NEXT FROM bPMOI_delete INTO @pmco, @project, @pcotype, @pco,
                @pcoitem, @aco, @contract, @changedays, @revacoitemid,
                @projectcopy
            IF @@fetch_status <> 0 
                BEGIN
                    SELECT  @errmsg = 'Cursor error'
                    GOTO error
                END
        END
   
   
    bPMOI_delete:
---- update change days for approved only
    IF ISNULL(@aco, '') <> '' 
        BEGIN
   	---- update bPMOH
            UPDATE  bPMOH
            SET     ChangeDays = ChangeDays - ISNULL(@changedays, 0)
            WHERE   PMCo = @pmco
                    AND Project = @project
                    AND ACO = @aco
   	---- Update JCCM Current Days
            EXEC @retcode = dbo.bspJCCMCurrentDaysUpdate @pmco, @contract
        END
   
	---- now process pending only
    IF ISNULL(@pco, '') <> '' 
        BEGIN
            IF @projectcopy = 'N' 
                BEGIN
			---- delete Pending Change Order Item Addons and Markups if not approving
                    IF NOT EXISTS ( SELECT  *
                                    FROM    bPMOL
                                    WHERE   PMCo = @pmco
                                            AND Project = @project
                                            AND PCOType = @pcotype
                                            AND PCO = @pco
                                            AND PCOItem = @pcoitem
                                            AND ISNULL(ACO, '') = '' ) 
                        BEGIN
				---- delete PMOA
                            DELETE  bPMOA
                            WHERE   PMCo = @pmco
                                    AND Project = @project
                                    AND PCOType = @pcotype
                                    AND PCO = @pco
                                    AND PCOItem = @pcoitem
				---- delete PMOM
                            DELETE  bPMOM
                            WHERE   PMCo = @pmco
                                    AND Project = @project
                                    AND PCOType = @pcotype
                                    AND PCO = @pco
                                    AND PCOItem = @pcoitem
                        END
                END

   	-- -- -- PendingStatus for PMOP:
   	-- -- -- 0) Pending - no items are approved and none are final
   	-- -- -- 1) Partial - At least one PCO Item has a beginning or intermediate status and no ACO#
   	-- -- -- 2) Approved - all PCO items have been approved
   	-- -- -- 3) Final - all PCO items are final or have been approved (ACO#)
   
   	---- get current status from bPMOP
            SELECT  @currentpendingstatus = PendingStatus
            FROM    bPMOP
            WHERE   PMCo = @pmco
                    AND Project = @project
                    AND PCOType = @pcotype
                    AND PCO = @pco
   
            SET @pendingstatus = 0
   	---- get current count of PCO Items from bPMOI
            SELECT  @pcoitem_count = COUNT(*)
            FROM    bPMOI
            WHERE   PMCo = @pmco
                    AND Project = @project
                    AND PCOType = @pcotype
                    AND PCO = @pco
                    AND PCOItem <> @pcoitem
            IF @pcoitem_count = 0 
                GOTO PendingStatus_Update
   
   	---- get count of pending PCO items
            SELECT  @pending_count = COUNT(*)
            FROM    bPMOI
                    JOIN bPMSC s ON s.Status = bPMOI.Status
            WHERE   PMCo = @pmco
                    AND Project = @project
                    AND PCOType = @pcotype
                    AND PCO = @pco
                    AND PCOItem <> @pcoitem
                    AND ISNULL(ACO, '') = ''
                    AND s.CodeType <> 'F'
   	---- if pending_count = pcoitem_count then status is pending.
            IF @pending_count = @pcoitem_count 
                BEGIN
                    SET @pendingstatus = 0
                    GOTO PendingStatus_Update
                END
   
   	---- get count of approved PCO items
            SELECT  @approved_count = COUNT(*)
            FROM    bPMOI
                    JOIN bPMSC s ON s.Status = bPMOI.Status
            WHERE   PMCo = @pmco
                    AND Project = @project
                    AND PCOType = @pcotype
                    AND PCO = @pco
                    AND PCOItem <> @pcoitem
                    AND ISNULL(ACO, '') <> ''
   	---- if approved_count = pcoitem_count then status is approved
            IF @approved_count = @pcoitem_count 
                BEGIN
                    SET @pendingstatus = 2
                    GOTO PendingStatus_Update
                END
   
   	---- get count of PCO Items that are approved or final
            SELECT  @appfinal_count = COUNT(*)
            FROM    bPMOI
                    JOIN bPMSC s ON s.Status = bPMOI.Status
            WHERE   PMCo = @pmco
                    AND Project = @project
                    AND PCOType = @pcotype
                    AND PCO = @pco
                    AND PCOItem <> @pcoitem
                    AND ( ISNULL(ACO, '') <> ''
                          OR s.CodeType = 'F'
                        )
   	---- if appfinal_count = pcoitem_count then items are all approved or final
            IF @appfinal_count = @pcoitem_count 
                BEGIN
                    SET @pendingstatus = 3
                    GOTO PendingStatus_Update
                END
   
   	---- if we are this far then the pending status is 1 - partial
            SET @pendingstatus = 1
   
   	---- now update bPMOP when status changes
            PendingStatus_Update:
            IF @pendingstatus <> @currentpendingstatus 
                BEGIN
                    UPDATE  bPMOP
                    SET     PendingStatus = @pendingstatus ,
                            ApprovalDate = NULL
                    WHERE   PMCo = @pmco
                            AND Project = @project
                            AND PCOType = @pcotype
                            AND PCO = @pco
                    IF @pendingstatus = 2 
                        BEGIN
                            UPDATE  bPMOP
                            SET     ApprovalDate = CONVERT(VARCHAR(11), GETDATE())
                            WHERE   PMCo = @pmco
                                    AND Project = @project
                                    AND PCOType = @pcotype
                                    AND PCO = @pco
                        END
                    IF @pendingstatus = 3 
                        BEGIN
                            UPDATE  bPMOP
                            SET     ApprovalDate = ( SELECT MAX(i.ApprovedDate)
                                                     FROM   bPMOI i
                                                     WHERE  i.PMCo = @pmco
                                                            AND i.Project = @project
                                                            AND i.PCOType = @pcotype
                                                            AND i.PCO = @pco
                                                            AND PCOItem <> @pcoitem
                                                            AND ISNULL(i.ACO,
                                                              '') <> ''
                                                   )
                            WHERE   PMCo = @pmco
                                    AND Project = @project
                                    AND PCOType = @pcotype
                                    AND PCO = @pco
                        END
                END
        END

---- remove reference to PMOI record in PMOA if any exist
    UPDATE  bPMOA
    SET     RevACOItemId = NULL ,
            RevACOItemAmt = NULL
    WHERE   RevACOItemId = @revacoitemid

    IF @numrows > 1 
        BEGIN
            FETCH NEXT FROM bPMOI_delete INTO @pmco, @project, @pcotype, @pco,
                @pcoitem, @aco, @contract, @changedays, @revacoitemid,
                @projectcopy
            IF @@fetch_status = 0 
                GOTO bPMOI_delete
            ELSE 
                BEGIN
                    CLOSE bPMOI_delete
                    DEALLOCATE bPMOI_delete
                    SET @opencursor = 0
                END
        END


---- document history (bPMDH)
    INSERT  INTO bPMDH
            ( PMCo ,
              Project ,
              Seq ,
              DocCategory ,
              DocType ,
              Document ,
              Rev ,
              ActionDateTime ,
              FieldType ,
              FieldName ,
              OldValue ,
              NewValue ,
              UserName ,
              Action ,
              PCOItem
            )
            SELECT  i.PMCo ,
                    i.Project ,
                    ISNULL(MAX(h.Seq), 0)
                    + ROW_NUMBER() OVER ( ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC ) ,
                    'PCO' ,
                    i.PCOType ,
                    i.PCO ,
                    NULL ,
                    GETDATE() ,
                    'D' ,
                    'PCOItem' ,
                    i.PCOItem ,
                    NULL ,
                    SUSER_SNAME() ,
                    'PCO: ' + ISNULL(i.PCO, '') + ' Item: ' + ISNULL(i.PCOItem,
                                                              '')
                    + ' has been deleted.' ,
                    i.PCOItem
            FROM    deleted i
                    LEFT JOIN bPMDH h ON h.PMCo = i.PMCo
                                         AND h.Project = i.Project
                                         AND h.DocCategory = 'PCO'
                    JOIN bPMCO c WITH ( NOLOCK ) ON i.PMCo = c.PMCo
                    LEFT JOIN bJCJM j WITH ( NOLOCK ) ON j.JCCo = i.PMCo
                                                         AND j.Job = i.Project
            WHERE   i.PCOItem IS NOT NULL
                    AND i.ACOItem IS NULL
                    AND j.ClosePurgeFlag <> 'Y'
                    AND ISNULL(c.DocHistPCO, 'N') = 'Y'
                    AND i.ProjectCopy = 'N'
            GROUP BY i.PMCo ,
                    i.Project ,
                    i.PCOType ,
                    i.PCO ,
                    i.PCOItem

---- ACO ITEM
    INSERT  INTO bPMDH
            ( PMCo ,
              Project ,
              Seq ,
              DocCategory ,
              DocType ,
              Document ,
              Rev ,
              ActionDateTime ,
              FieldType ,
              FieldName ,
              OldValue ,
              NewValue ,
              UserName ,
              Action ,
              ACOItem
            )
            SELECT  i.PMCo ,
                    i.Project ,
                    ISNULL(MAX(h.Seq), 0)
                    + ROW_NUMBER() OVER ( ORDER BY i.PMCo ASC, i.Project ASC ) ,
                    'ACO' ,
                    NULL ,
                    i.ACO ,
                    NULL ,
                    GETDATE() ,
                    'D' ,
                    'ACOItem' ,
                    i.ACOItem ,
                    NULL ,
                    SUSER_SNAME() ,
                    'ACO: ' + ISNULL(i.ACO, '') + ' Item: ' + ISNULL(i.ACOItem,
                                                              '')
                    + ' has been deleted.' ,
                    i.ACOItem
            FROM    deleted i
                    LEFT JOIN bPMDH h ON h.PMCo = i.PMCo
                                         AND h.Project = i.Project
                                         AND h.DocCategory = 'ACO'
                    JOIN bPMCO c WITH ( NOLOCK ) ON i.PMCo = c.PMCo
                    LEFT JOIN bJCJM j WITH ( NOLOCK ) ON j.JCCo = i.PMCo
                                                         AND j.Job = i.Project
            WHERE   i.ACO IS NOT NULL
                    AND i.ACOItem IS NOT NULL
                    AND j.ClosePurgeFlag <> 'Y'
                    AND ISNULL(c.DocHistACO, 'N') = 'Y'
                    AND i.ProjectCopy = 'N'
            GROUP BY i.PMCo ,
                    i.Project ,
                    i.ACO ,
                    i.ACOItem

    RETURN

    error:
    IF @opencursor = 1 
        BEGIN
            CLOSE bPMOI_delete
            DEALLOCATE bPMOI_delete
            SET @opencursor = 0
        END
   
    SELECT  @errmsg = ISNULL(@errmsg, '')
            + ' - cannot delete Change Order Item PMOI'
    RAISERROR(@errmsg, 11, -1);
    ROLLBACK TRANSACTION
   
   
   
  
 












GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMOIi    Script Date: 8/28/99 9:37:56 AM ******/
CREATE  trigger [dbo].[btPMOIi] on [dbo].[bPMOI] for INSERT as
/*--------------------------------------------------------------------------
 * Insert trigger for PMOI
 * Created By:	JRE 04/05/1998
 * Modified By:	GF 04/28/2000
 *				TV 04/03/2001 Verifies that PMOH changedays is in sync with approve3d Items
 *				GF 10/09/2002 - changed dbl quotes to single quotes
 *				GF 11/19/2002 - Added TotalType flag to insert into PMOA
 *				GF 11/10/2003 - issue #22944 JCCM.CurrentDays update
 *				GF 08/06/2004 - issue #25311 Added Include flag to insert into bPMOA
 *				GF 11/09/2004 - issue #22768 additional pending status's. Also cleanup trigger cursor
 *				GF 11/22/2005 - issue #30402 for approved status, where clause was wrong. using status <> 'F'
 *				GF 05/04/2006 - issue #121077 - fix for project copy when pco and aco items are copied.
 *				GF 11/26/2006 - 6.x document history
 *				GF 02/05/2007 - issue #123699 issue history
 *				GF 02/29/2008 - issue #127210 additional columns for PMOA insert statement
 *				GF 10/30/2008 - issue #130772 expanded description to 60 characters
 *				GF 01/13/2009 - issue #129669 distribute cost type addons and set PMOA Status = Y
 *				GF 03/05/2009 - issue #132046 addons option to not create for internal and PMDT.InitAddons <> 'Y'
 *				GF 03/01/2010 - issue #138307 added isnull for notes.
 *				GF 08/03/2010 - issue #134354 addons option to only insert based on Standard Flag
 *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - tfs #398
 *				GF 05/24/2011 - TK-05347 ready for accounting flag
 *				GF 06/20/2011 - TK-06039
 *				GF 11/23/2011 - TK-10530 CI#145134 
 *				DAN SO 03/12/20120 - TK-13118 - Added nulls to vspPMPCOApprovePMSL and vspPMPCOApprovePMMF calls
 *				JayR 03/23/2012 - TK-00000 Change to use FKs for validation
 *
 *
 *  This one is kinda of tricky because if inserting An ACO that has a PCO
 *  we will actually delete the record and update the PCO with the ACO stuff
 *-------------------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @rcode int, @validcnt int,@validcnt1 int, 
  		@validcnt2 int, @retcode int, @retmsg varchar(255), @opencursor tinyint,
  		@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO, @pcoitem bPCOItem,
  		@aco bACO, @acoitem bACOItem, @testaco bACO, @testacoitem bACOItem, @description bItemDesc,
  		@contract bContract, @contractitem bContractItem, @status bStatus, 
  		@approveddate bDate, @approved bYN, @approvedby bVPUserName, @date1 bDate, 
  		@date2 bDate, @date3 bDate, @um bUM, @units bUnits, @unitprice bUnitCost,
  		@pendingamount bDollar, @approvedamt bDollar, @fixedamountyn bYN, @fixedamount bDollar,
  		@forcephaseyn bYN, @changedays smallint, @pendingstatus tinyint, @currentpendingstatus tinyint, 
  		@pcoitem_count int, @pending_count int, @approved_count int, @appfinal_count int,
		@projectcopy bYN, @olddesc bItemDesc, @oldstatus bStatus, @oldapproveddate bDate, @oldum bUM,
		@oldunits bUnits, @oldapprovedamt bDollar, @oldcontitem bContractItem, @oldchangedays smallint,
		@oldapprovedyn bYN, @oldapprovedby bVPUserName, @oldforcephaseyn bYN, @intext char(1)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

select @opencursor = 0

------ Validate Approved Header
--select @validcnt = count(*) from bPMOH r JOIN inserted i ON
--  			i.PMCo = r.PMCo and i.Project=r.Project and i.ACO=r.ACO
--select @validcnt2 = count(*) from inserted i Where i.ACO is null
--if @validcnt + @validcnt2 <> @numrows
--  	begin
--  	select @errmsg = 'ACO header is Invalid'
--  	goto error
--  	end

---- Validate Pending Header
--select @validcnt = count(*) from bPMOP r JOIN inserted i ON
--  			i.PMCo = r.PMCo and i.Project=r.Project and i.PCOType=r.PCOType and i.PCO=r.PCO
--select @validcnt2 = count(*) from inserted i Where i.PCO is null
--if @validcnt + @validcnt2 <> @numrows
--  	begin
--  	select @errmsg = 'PCO header is Invalid '
--  	goto error
--  	end

---- Validate Contract Item
--select @validcnt = count(*) from bJCCI r JOIN inserted i ON
--  			i.PMCo = r.JCCo and i.Contract = r.Contract and i.ContractItem=r.Item
--select @validcnt2 = count(*) from inserted i Where i.ContractItem is null
--if @validcnt + @validcnt2 <> @numrows
--  	begin
--  	select @errmsg = 'Contract Item is Invalid '
--  	goto error
--  	end


---- create cursor on inserted rows to update header
if @numrows = 1
	begin
  	select @pmco=PMCo, @project=Project, @aco=ACO, @acoitem=ACOItem, @pcotype=PCOType, @pco=PCO,
  				@pcoitem=PCOItem, @description=Description
  	from inserted
	end
else
  	begin
  	---- use a cursor to process each updated row
  	declare bPMOI_insert cursor LOCAL FAST_FORWARD
  	for select PMCo, Project, ACO, ACOItem, PCOType, PCO, PCOItem, Description
  	from inserted
  
  	open bPMOI_insert
  	set @opencursor = 1
  	
  	fetch next from bPMOI_insert into @pmco, @project, @aco, @acoitem, @pcotype, @pco, @pcoitem, @description
  	if @@fetch_status <> 0
  		begin
  		select @errmsg = 'Cursor error'
  		goto error
  		end
  	end

bPMOI_insert:
---- process ACO side first
if isnull(@aco,'') <> ''
  	begin
  	-- -- -- get rest of data
  	select @status=Status, @approveddate=ApprovedDate, @um=UM,
  			@units=Units, @unitprice=UnitPrice, @pendingamount=PendingAmount,
  			@approvedamt=ApprovedAmt, @date1=Date1, @date2=Date2, @date3=Date3,
  			@contract=Contract, @contractitem=ContractItem, @changedays=ChangeDays,
  			@approved=Approved, @approvedby=ApprovedBy, @forcephaseyn=ForcePhaseYN,
  			@fixedamountyn=FixedAmountYN, @fixedamount=FixedAmount, @projectcopy=ProjectCopy
  	from inserted where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
 
  	---- Updates PMOH.ChangeDays if this is a ACO
  	update bPMOH
  	set ChangeDays = (select sum(isnull(ChangeDays,0)) from bPMOI where PMCo=@pmco and ACO=@aco and Project=@project)
  	where PMCo=@pmco and ACO=@aco and Project=@project
  	---- Update JCCM.CurrentDays
  	exec @retcode = dbo.bspJCCMCurrentDaysUpdate @pmco, @contract

	---- if inserted record has aco and pco information then item is being copied and can skip to pco section
	if @pcotype is not null and @pco is not null and @pcoitem is not null and @aco is not null and @acoitem is not null and @projectcopy = 'Y' goto PCO_Section

  	---- check if it is a new ACO being applied to a PCO
  	---- find if the Pending Change order is already bound to an ACO
  	if isnull(@pcotype,'') <> ''
  		begin
		---- retrieve the int/ext from the pending header record
		select @intext=IntExt from bPMOP with (nolock)
		where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
		if isnull(@intext,'') = '' select @intext='E'

  		select @testaco=ACO, @testacoitem=ACOItem
  		from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
  		if @@rowcount=0
  			begin
  			select @errmsg = 'PCO is Invalid '
  			goto error
  			end
  
  		if isnull(@testaco,'') <> '' or isnull(@testacoitem,'') <> ''
  			begin
  			---- different ACO
  			if @testaco <> @aco
  				begin
  				select @errmsg = 'PCO Item is already on a different ACO!'
  				goto error
  				end
  			---- different ACO Item
  			if @testacoitem <> @acoitem
  				begin
  				select @errmsg = 'PCO Item is already on a different ACO Item!'
  				goto error
  				end
  			end
  
  		-- drop this record and update the original record
		---- update copy flag so that history not recorded
		---- HACK
		update bPMOI set ProjectCopy='Y'
		where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
		
		
		
		
		  	--select @errmsg = '**** DAN SO TESTING **** pmco: ' +
		  	--				cast(@pmco as varchar(10)) + ' project: ' +
		  	--				cast(@project as varchar(10)) + ' aco: ' +
		  	--				cast(@aco as varchar(10)) + '  acoitem: ' +
		  	--				cast(@acoitem as varchar(10))
  			--	goto error
  				
		
		
		
		
		---- now delete
  		delete from bPMOI
  		where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
		---- get PCO item info
		select @olddesc=Description, @oldstatus=Status, @oldapproveddate=ApprovedDate, @oldum=UM,
				@oldunits=Units, @oldapprovedamt=ApprovedAmt, @oldcontitem=ContractItem,
				@oldapprovedyn=Approved, @oldapprovedby=ApprovedBy, @oldforcephaseyn=ForcePhaseYN,
				@oldchangedays=ChangeDays
		from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
  		if @@rowcount=0
  			begin
  			select @errmsg = 'PCO Item is Invalid '
  			goto error
  			end

  		---- update bPMOI
  		Update bPMOI set ACO=@aco, ACOItem=@acoitem, Description=@description, Status=@status,
  				ApprovedDate=@approveddate, UM=@um, Units=@units, UnitPrice=@unitprice,
  				ApprovedAmt=@approvedamt, Contract=@contract, ContractItem=@contractitem,
  				Approved=@approved, ApprovedBy=@approvedby, ForcePhaseYN=@forcephaseyn,
				ChangeDays=@changedays
  	  	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
  		---- update bPMOL
  		Update bPMOL set ACO=@aco, ACOItem=@acoitem
  		where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
  		---- update bPMMF
  		Update bPMMF set ACO=@aco, ACOItem=@acoitem
  		where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
    	---- update bPMSL TK-06039
  		Update bPMSL set ACO=@aco, ACOItem=@acoitem
  		where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
  		
  	    ---- create SubCO when approved manually TK-06039
  	    select @retcode=0, @retmsg=''
  	    exec @retcode = dbo.vspPMPCOApprovePMSL @pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, 'A', NULL, 
  						-- TK-13118 --
  						NULL, NULL, 
  						@retmsg output
  	    if @retcode <> 0
  	       begin
  	       select @errmsg = @retmsg, @rcode = @retcode
  	       goto error
  	       end

  	    ---- create POCONum when approved manually TK-06039
  	    select @retcode=0, @retmsg=''
  	    exec @retcode = dbo.vspPMPCOApprovePMMF @pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, 'A', NULL, 
  						-- TK-13118 --
  						NULL, NULL, 
  						@retmsg output
  	    if @retcode <> 0
  	       begin
  	       select @errmsg = @retmsg, @rcode = @retcode
  	       goto error
  	       END
  	    
		---- now lets add any add-on phase cost types that are being distributed to #129669
		exec @retcode = dbo.vspPMPCOAddonDistCosts @pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem, @retmsg output
		if @retcode <> 0
			begin
			select @errmsg = @retmsg, @rcode = @retcode
			goto error
			end

		if isnull(@description,'') <> isnull(@olddesc,'')
			begin
			insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
					FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
			select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
					'ACO', null, @aco, null, getdate(), 'C', 'Description', @olddesc, @description,
					SUSER_SNAME(), 'Description has been changed', @pcoitem, @acoitem
			from inserted i
			left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
			join bPMCO c with (nolock) on i.PMCo=c.PMCo
			where isnull(c.DocHistACO,'N') = 'Y'
			group by i.PMCo, i.Project, i.ACO, i.ACOItem
			end
		if isnull(@contractitem,'') <> isnull(@oldcontitem,'')
			begin
			insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
					FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
			select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
					'ACO', null, @aco, null, getdate(), 'C', 'ContractItem', @oldcontitem, @contractitem,
					SUSER_SNAME(), 'Contract Item has been changed', @pcoitem, @acoitem
			from inserted i
			left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
			join bPMCO c with (nolock) on i.PMCo=c.PMCo
			where isnull(c.DocHistACO,'N') = 'Y'
			group by i.PMCo, i.Project, i.ACO, i.ACOItem
			end
		if isnull(@um,'') <> isnull(@oldum,'')
			begin
			insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
					FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
			select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
					'ACO', null, @aco, null, getdate(), 'C', 'UM', @oldum, @um,
					SUSER_SNAME(), 'Contract Item has been changed', @pcoitem, @acoitem
			from inserted i
			left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
			join bPMCO c with (nolock) on i.PMCo=c.PMCo
			where isnull(c.DocHistACO,'N') = 'Y'
			group by i.PMCo, i.Project, i.ACO, i.ACOItem
			end
		if isnull(@units,0) <> isnull(@oldunits,0)
			begin
			insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
					FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
			select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
					'ACO', null, @aco, null, getdate(), 'C', 'Units', isnull(convert(varchar(16),@oldunits),0), isnull(convert(varchar(16),@units),0),
					SUSER_SNAME(), 'Units has been changed', @pcoitem, @acoitem
			from inserted i
			left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
			join bPMCO c with (nolock) on i.PMCo=c.PMCo
			where isnull(c.DocHistACO,'N') = 'Y'
			group by i.PMCo, i.Project, i.ACO, i.ACOItem
			end
		if isnull(@approvedamt,0) <> isnull(@oldapprovedamt,0)
			begin
			insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
					FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
			select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
					'ACO', null, @aco, null, getdate(), 'C', 'ApprovedAmt', convert(varchar(16),isnull(@oldapprovedamt,0)), convert(varchar(16),isnull(@approvedamt,0)),
					SUSER_SNAME(), 'Approved Amt has been changed', @pcoitem, @acoitem
			from inserted i
			left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
			join bPMCO c with (nolock) on i.PMCo=c.PMCo
			where isnull(c.DocHistACO,'N') = 'Y'
			group by i.PMCo, i.Project, i.ACO, i.ACOItem
			END
			
		if isnull(@forcephaseyn,'') <> isnull(@oldforcephaseyn,'')
			begin
			insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
					FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
			select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
					'ACO', null, @aco, null, getdate(), 'C', 'ForcePhase', @oldforcephaseyn, @forcephaseyn,
					SUSER_SNAME(), 'Force Phase Flag has been changed', @pcoitem, @acoitem
			from inserted i
			left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
			join bPMCO c with (nolock) on i.PMCo=c.PMCo
			where isnull(c.DocHistACO,'N') = 'Y'
			group by i.PMCo, i.Project, i.ACO, i.ACOItem
			end

		if isnull(@changedays,0) <> isnull(@oldchangedays,0)
			begin
			insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
					FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
			select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
					'ACO', null, @aco, null, getdate(), 'C', 'ChangeDays', isnull(convert(varchar(8),@oldchangedays),''), isnull(convert(varchar(8),@changedays),0),
					SUSER_SNAME(), 'Change Days has been changed', @pcoitem, @acoitem
			from inserted i
			left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
			join bPMCO c with (nolock) on i.PMCo=c.PMCo
			where isnull(c.DocHistACO,'N') = 'Y'
			group by i.PMCo, i.Project, i.ACO, i.ACOItem
			end

  		END ---- end of checking if assigned to PCO
  	end
  
  
PCO_Section:
---- PCO side
if isnull(@pco,'') <> ''
  	begin
	if isnull(@acoitem,'') = ''
		begin
  		---- insert into PMOA - Pending CO Item Addons
  		insert into dbo.bPMOA (PMCo, Project, PCOType, PCO, PCOItem, AddOn, Basis, AddOnPercent,
				AddOnAmount, TotalType, Include, NetCalcLevel, BasisCostType, PhaseGroup, Status)
  		select @pmco, @project, @pcotype, @pco, @pcoitem, p.AddOn, p.Basis, isnull(p.Pct,0),
				isnull(p.Amount,0), p.TotalType, p.Include, p.NetCalcLevel, p.BasisCostType, p.PhaseGroup, 'Y'
  		from dbo.bPMPA p
		----#132046
		join dbo.bPMOP h on h.PMCo=p.PMCo and h.Project=@project and h.PCOType=@pcotype and h.PCO=@pco
		join dbo.bPMDT t on t.DocType=h.PCOType
		----#134354
		where p.PMCo=@pmco and p.Project=@project and p.Standard = 'Y'
		and (h.IntExt = 'E' or (h.IntExt = 'I' and t.InitAddons = 'Y'))
  		and not exists (select 1 from dbo.bPMOA q where q.PMCo=@pmco and q.Project=@project and q.PCOType=@pcotype
  					 and q.PCO=@pco and q.PCOItem=@pcoitem and q.AddOn=p.AddOn)
		end
  
  	-- -- -- PendingStatus for PMOP:
  	-- -- -- 0) Pending - no items are approved and none are final
  	-- -- -- 1) Partial - At least one PCO Item has a beginning or intermediate status and no ACO#
  	-- -- -- 2) Approved - all PCO items have been approved
  	-- -- -- 3) Final - all PCO items are final or have been approved (ACO#)
  
  	---- get current status from bPMOP
  	select @currentpendingstatus=PendingStatus
  	from bPMOP where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
  
  	set @pendingstatus = 0
  	---- get current count of PCO Items from bPMOI
  	select @pcoitem_count = count(*)
  	from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
  	if @pcoitem_count = 0 goto PendingStatus_Update
  
  	---- get count of unapproved, none are final PCO items
  	select @pending_count = count(*)
  	from bPMOI join bPMSC s on s.Status=bPMOI.Status
  	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
  	and isnull(ACO,'') = '' and s.CodeType <> 'F'
  	---- if pending_count = pcoitem_count then status is pending.
  	if @pending_count = @pcoitem_count
  		begin
  		set @pendingstatus = 0
  		goto PendingStatus_Update
  		end
  
  	---- get count of approved, none are final PCO items
  	select @approved_count = count(*)
  	from bPMOI join bPMSC s on s.Status=bPMOI.Status
  	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco 
  	and isnull(ACO,'') <> ''
  	---- if approved_count = pcoitem_count then status is approved
  	if @approved_count = @pcoitem_count
  		begin
  		set @pendingstatus = 2
  		goto PendingStatus_Update
  		end
  
  	---- get count of PCO Items that are approved or final
  	select @appfinal_count = count(*)
  	from bPMOI join bPMSC s on s.Status=bPMOI.Status
  	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
  	and (isnull(ACO,'') <> '' or s.CodeType = 'F')
  	---- if appfinal_count = pcoitem_count then items are all approved or final
  	if @appfinal_count = @pcoitem_count
  		begin
  		set @pendingstatus = 3
  		goto PendingStatus_Update
  		end
  
  	---- if we are this far then the pending status is 1 - partial
  	set @pendingstatus = 1
 
  	---- now update bPMOP when status changes
  	PendingStatus_Update:
  	if @pendingstatus <> @currentpendingstatus
  		begin
  		update bPMOP set PendingStatus=@pendingstatus, ApprovalDate=null
  		where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
  		if @pendingstatus = 2
  			begin
  			update bPMOP set ApprovalDate=convert(varchar(11),GetDate()) 
  			where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
  			end
  		if @pendingstatus = 3
  			begin
  			update bPMOP set ApprovalDate=(select max(i.ApprovedDate) from bPMOI i where i.PMCo=@pmco
  					and i.Project=@project and i.PCOType=@pcotype and i.PCO=@pco and isnull(i.ACO,'') <> '')
  			where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
  			end
  		end
  	end

if @numrows > 1
  	begin
  	fetch next from bPMOI_insert into @pmco, @project, @aco, @acoitem, @pcotype, @pco, @pcoitem, @description
   	if @@fetch_status = 0
   		goto bPMOI_insert
   	else
   		begin
   		close bPMOI_insert
   		deallocate bPMOI_insert
  		set @opencursor = 0
   		end
   	end



---- update the ready for accounting flag to 'Y' in PMOH
---- when added to an ACO and the flag is 'N' TK-05347
----TK-10530 CI#145134 
UPDATE dbo.bPMOH SET ReadyForAcctg = 'Y'
FROM inserted i
INNER JOIN dbo.bPMOH h ON h.PMCo=i.PMCo AND h.Project=i.Project AND h.ACO=i.ACO
WHERE i.ACO IS NOT NULL AND h.ReadyForAcctg = 'N'


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
		'PCO', i.PCOType, i.PCO, null, getdate(), 'A', 'PCOItem', null, i.PCOItem, SUSER_SNAME(),
		'PCO: ' + isnull(i.PCO,'') + ' Item: ' + isnull(i.PCOItem,'') + ' has been added.', i.PCOItem
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistPCO,'N') = 'Y' and i.PCOItem is not null
and i.ACOItem is null 
group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem

---- ACO Items - approved only
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'ACO', null, i.ACO, null, getdate(), 'A', 'ACOItem', null, i.ACOItem, SUSER_SNAME(),
		'ACO: ' + isnull(i.ACO,'') + ' Item: ' + isnull(i.ACOItem,'') + ' has been added.', i.ACOItem
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistACO,'N') = 'Y' and i.ACO is not NULL
----#138307
and i.ACOItem is not null and i.PCOItem is null and ISNULL(i.Notes,'') <> 'Revenue Item'
group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.PCOItem


insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'ACO', null, i.ACO, null, getdate(), 'A', 'ACOItem', null, i.ACOItem, SUSER_SNAME(),
		'ACO: ' + isnull(i.ACO,'') + ' Item: ' + isnull(i.ACOItem,'') + ' has been approved from PCOType: ' + isnull(i.PCOType,'') + ' PCO: ' + isnull(i.PCO,'') + ' PCOItem: ' + isnull(i.PCOItem,''),
		i.PCOItem, i.ACOItem
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistACO,'N') = 'Y' and i.ACO is not null
and i.ACOItem is not null and i.PCOItem is not null
group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.PCOItem, i.PCOType, i.PCO

return

error:
  	if @opencursor = 1
  		begin
  		close bPMOI_insert
  		deallocate bPMOI_insert
  		set @opencursor = 0
  		end
  
  	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMOI'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
 
 
 



























GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMOIu    Script Date: 8/28/99 9:37:56 AM ******/
CREATE  trigger [dbo].[btPMOIu] on [dbo].[bPMOI] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMOI
 * Created By:	LM	9/2/98
 * Modified By:	TV	04/03/01 - Update Change of Days PMOH
 *				GF 10/09/2002 - changed dbl quotes to single quotes
 *				GF 11/10/2003 - issue #22944 - JCCM.CurrentDays update
 *				GF 11/11/2004 - issue #22768 additional pending status's. Also cleanup trigger cursor
 *				GF 11/26/2006 - 6.x
*				GF 10/30/2008 - issue #130772 expanded description to 60 characters
 *				GF 10/08/2010 - issue #141648
*				GF 01/26/2011 - tfs #398 no issue history
 *				GF 04/08/2011 - TK-03289
 *				GF 04/22/2011 - TK-04303
 *				GF 06/20/2011 - TK-06121
 *				GF 06/22/2011 - D-02339 use view not tables for links
 *				GF 01/17/2011 - TK-11599 #145091 begin status for PMOP
 *				JayR 03/23/2012 - TK-00000 Change to use FKs for validation
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @rcode int, @validcnt int, @validcnt1 int, @validcnt2 int,
   		@opencursor tinyint, @retcode int, @key varchar(1000), @description bItemDesc,
   		@pmco bCompany, @project bJob, @pcotype bDocType, @pco bDocument, @pcoitem bPCOItem,
   		@aco bDocument, @acoitem bACOItem, @status bStatus, @approveddate bDate, @date1 bDate,
   		@date2 bDate, @date3 bDate, @contractitem bContractItem, @changedays smallint,
   		@pendingamount bDollar, @approvedamt bDollar, @oldstatus bStatus, @oldapproveddate bDate,
   		@olddate1 bDate, @olddate2 bDate, @olddate3 bDate, @contract bContract, @oldcontractitem bContractItem,
   		@oldchangedays smallint, @oldpendingamount bDollar, @oldapprovedamt bDollar,
   		@currentpendingstatus tinyint, @pendingstatus tinyint, @pcoitem_count int, @pending_count int,
   		@approved_count int, @appfinal_count INT,
   		----TK-11599
   		@begin_status bStatus

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

set @opencursor = 0

---- check for change to primary key
---- updates are allowed to PCOType, PCO, PCOItem, ACO and ACOItem
if update(PMCo) or update(Project)
   	begin
	select @errmsg = 'Changes to PM Company or Project is not allowed.'
	goto error
	end


---- create cursor on inserted rows to update status
if @numrows = 1
	begin
   	select @pmco=PMCo, @project=Project, @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem, @aco=ACO, @acoitem=ACOItem
   	from inserted
	end
else
   	begin
   	---- use a cursor to process each updated row
   	declare bPMOI_insert cursor LOCAL FAST_FORWARD
   	for select PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem
   	from inserted
   
   	open bPMOI_insert
   	set @opencursor = 1
   	
   	fetch next from bPMOI_insert into @pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end


bPMOI_insert:
---- process PCO's first
if isnull(@pco,'') <> ''
   BEGIN
   	---- PendingStatus for PMOP:
   	---- 0) Pending - no items are approved and none are final
   	---- 1) Partial - some are approved	or at least one PCO item is pending,
   	---- 	some are final or at least one PCO item is pending, some are approved, some are final
   	---- 2) Approved - all PCO items have been approved, and none are final.
   	---- 3) Final - all PCO items are final, but none of the PCO items have been approved.
   	---- 4) App/Final - every PCO item is final or has been approved

	---- retrieve a beginning status code for pco header
	---- so that if we are unapproving all items for a PCO and the system status
	---- goes back to 0 - pending then we can set the status to a beginning status
	---- look a PMCO, PMSC for PCO category, first in PMSC for a begin type
	----TK-11599
	SET @begin_status = NULL
	select @begin_status = BeginStatus
	from dbo.bPMCO
	WHERE PMCo=@pmco
	IF ISNULL(@begin_status,'') = ''
		BEGIN
		SELECT TOP 1 @begin_status = [Status]
		FROM dbo.bPMSC
		WHERE CodeType = 'B'
			AND ActiveAllYN = 'N'
			AND DocCat = 'PCO'
		GROUP BY CodeType, ActiveAllYN, DocCat, [Status]
		IF @@ROWCOUNT = 0
			BEGIN
			SELECT TOP 1 @begin_status = [Status]
			FROM dbo.bPMSC
			WHERE CodeType = 'B'
				AND ActiveAllYN = 'Y'
			GROUP BY CodeType, ActiveAllYN, [Status]
			IF @@ROWCOUNT = 0 SET @begin_status = NULL
			END
		END
	
   	---- get current status from bPMOP
   	select @currentpendingstatus=PendingStatus
   	from bPMOP where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   
   	set @pendingstatus = 0
   	---- get current count of PCO Items from bPMOI
   	select @pcoitem_count = count(*)
   	from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   	if @pcoitem_count = 0 goto PendingStatus_Update
   
   	---- get count of unapproved, none are final PCO items
   	select @pending_count = count(*)
   	from bPMOI join bPMSC s on s.Status=bPMOI.Status
   	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   	and isnull(ACO,'') = '' and s.CodeType <> 'F'
   	---- if pending_count = pcoitem_count then status is pending.
   	if @pending_count = @pcoitem_count
   		begin
   		set @pendingstatus = 0
   		goto PendingStatus_Update
   		end
   
   	---- get count of approved, none are final PCO items
   	select @approved_count = count(*)
   	from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   	and isnull(ACO,'') <> ''
   	---- if approved_count = pcoitem_count then status is approved
   	if @approved_count = @pcoitem_count
   		begin
   		set @pendingstatus = 2
   		goto PendingStatus_Update
   		end
   
   	---- get count of PCO Items that are approved or final
   	select @appfinal_count = count(*)
   	from bPMOI join bPMSC s on s.Status=bPMOI.Status
   	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   	and (isnull(ACO,'') <> '' or s.CodeType = 'F')
   	---- if appfinal_count = pcoitem_count then items are all approved or final
   	if @appfinal_count = @pcoitem_count
   		begin
   		set @pendingstatus = 3
   		goto PendingStatus_Update
   		end
   
   	---- if we are this far then the pending status is 1 - partial
   	set @pendingstatus = 1
   
   	---- now update bPMOP when status changes
   	PendingStatus_Update:
   	if @pendingstatus <> @currentpendingstatus
   		begin
   		update bPMOP set PendingStatus=@pendingstatus,
   						 ApprovalDate=NULL,
   						 ----TK-11599
   						 [Status] = CASE WHEN @pendingstatus = 0 THEN @begin_status ELSE a.[Status] END
   		FROM dbo.bPMOP a
   		WHERE a.PMCo=@pmco and a.Project=@project
   		and a.PCOType=@pcotype and a.PCO=@pco
   		if @pendingstatus = 2
   			begin
   			update bPMOP set ApprovalDate=convert(varchar(11),GetDate()) 
   			where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   			end
   		if @pendingstatus = 3
   			begin
   			update bPMOP set ApprovalDate=(select max(i.ApprovedDate) from bPMOI i where i.PMCo=@pmco
   					and i.Project=@project and i.PCOType=@pcotype and i.PCO=@pco and isnull(i.ACO,'') <> '')
   			where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
   			end
   		end
      
	END



---- process ACO's
if isnull(@aco,'') <> ''
   BEGIN
   	---- get inserted data
   	select @description=Description, @status=Status, @approveddate=ApprovedDate, 
   			@approvedamt=ApprovedAmt, @contract=Contract, @contractitem=ContractItem
   	from inserted where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
   	---- get deleted data
   	select @oldstatus=Status, @oldapproveddate=ApprovedDate, @oldapprovedamt=ApprovedAmt,
   			@oldcontractitem=ContractItem
   	from deleted where  PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
   
   	---- build action key
   	select @key = ' for ACO: ' + isnull(@aco,'') + ' Item: ' + isnull(@acoitem,'') + ' - ' + isnull(@description,'') + ', has changed from '
   
   	---- updates PMOH.ChangeDays for ACO's only
   	update bPMOH set ChangeDays = (select sum(isnull(ChangeDays,0))from bPMOI with (nolock) 
   						where PMCo=@pmco and Project=@project and ACO=@aco)
   	where PMCo=@pmco and Project=@project and ACO=@aco
   
   	---- update JCCM Current Days
   	exec @retcode = dbo.bspJCCMCurrentDaysUpdate @pmco, @contract
   
	END



if @numrows > 1
	begin
   	fetch next from bPMOI_insert into @pmco, @project, @pcotype, @pco, @pcoitem, @aco, @acoitem
	if @@fetch_status = 0
		begin
		goto bPMOI_insert
		end
	else
		begin
		close bPMOI_insert
		deallocate bPMOI_insert
   		set @opencursor = 0
		end
	end



---- document history check PMCO.DocHistPCO and PMCO.DocHistACO flags
if not exists(select top 1 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and isnull(c.DocHistPCO,'N') = 'Y')
	begin
  	goto ACO_side
	end

---- PMDH inserts
if update(ACOItem)
	begin
	---- when approved
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'ACOItem', d.ACOItem, i.ACOItem,
			SUSER_SNAME(), 'PCO Item has been approved to ACO: ' + isnull(i.ACO,'') + '/' + isnull(i.ACOItem,''),
			i.PCOItem, i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ACOItem,'') <> isnull(i.ACOItem,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is not null and d.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.ACO, i.ACOItem, d.ACOItem
	---- when unapproved
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'ACOItem', d.ACOItem, i.ACOItem,
			SUSER_SNAME(), 'PCO Item has been unapproved.', i.PCOItem, d.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ACOItem,'') <> isnull(i.ACOItem,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null and d.ACOItem is not null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.ACO, i.ACOItem, d.ACOItem
	end

---- PCO side only
if update(Description)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Description', d.Description, i.Description,
			SUSER_SNAME(), 'Description has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.Description, d.Description
	end
if update(Status)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Status', d.Status, i.Status,
			SUSER_SNAME(), 'Status has been changed', i.PCOItem, i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null and d.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.ACOItem, i.Status, d.Status
	end
if update(Date1)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Date1', convert(char(8),d.Date1,1),
			convert(char(8),i.Date1,1), SUSER_SNAME(), 'Date 1 has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Date1,'') <> isnull(i.Date1,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.Date1, d.Date1
	end
if update(Date2)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Date2', convert(char(8),d.Date2,1),
			convert(char(8),i.Date2,1), SUSER_SNAME(), 'Date 2 has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Date2,'') <> isnull(i.Date2,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.Date2, d.Date2
	end
if update(Date3)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Date3', convert(char(8),d.Date3,1),
			convert(char(8),i.Date3,1), SUSER_SNAME(), 'Date 3 has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Date3,'') <> isnull(i.Date3,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.Date3, d.Date3
	end
if update(UM)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'UM', d.UM, i.UM,
			SUSER_SNAME(), 'UM has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.UM,'') <> isnull(i.UM,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.UM, d.UM
	end
if update(ForcePhaseYN)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'ForcePhaseYN', d.ForcePhaseYN, i.ForcePhaseYN,
			SUSER_SNAME(), 'Force Phase flag has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ForcePhaseYN,'') <> isnull(i.ForcePhaseYN,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.ForcePhaseYN, d.ForcePhaseYN
	end
if update(ContractItem)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'ContractItem', d.ContractItem, i.ContractItem,
			SUSER_SNAME(), 'Contract Item has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ContractItem,'') <> isnull(i.ContractItem,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.ContractItem, d.ContractItem
	end

if update(ChangeDays)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'ChangeDays', convert(varchar(6),d.ChangeDays), convert(varchar(6),i.ChangeDays),
			SUSER_SNAME(), 'Change Days has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ChangeDays,'') <> isnull(i.ChangeDays,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.ChangeDays, d.ChangeDays
	end
if update(FixedAmountYN)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'FixedAmountYN', d.FixedAmountYN, i.FixedAmountYN,
			SUSER_SNAME(), 'Fixed Amount flag has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.FixedAmountYN,'') <> isnull(i.FixedAmountYN,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.FixedAmountYN, d.FixedAmountYN
	end
if update(Units)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'Units', convert(varchar(16),d.Units), convert(varchar(16),i.Units),
			SUSER_SNAME(), 'Units have been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Units,'') <> isnull(i.Units,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.Units, d.Units
	end
if update(UnitPrice)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'UnitPrice', convert(varchar(16),d.UnitPrice), convert(varchar(16),i.UnitPrice),
			SUSER_SNAME(), 'Unit Price has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(convert(varchar(16),d.UnitPrice),'') <> isnull(convert(varchar(16),i.UnitPrice),'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null and i.FixedAmountYN = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.UnitPrice, d.UnitPrice
	end
if update(FixedAmount)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'FixedAmount', convert(varchar(16),d.FixedAmount), convert(varchar(16),i.FixedAmount),
			SUSER_SNAME(), 'Fixed Amount has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(convert(varchar(16),d.FixedAmount),'') <> isnull(convert(varchar(16),i.FixedAmount),'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null and i.FixedAmountYN = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.FixedAmount, d.FixedAmount
	end
if update(BudgetNo)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'BudgetNo', d.BudgetNo, i.BudgetNo,
			SUSER_SNAME(), 'Budget No. has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.BudgetNo,'') <> isnull(i.BudgetNo,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.BudgetNo, d.BudgetNo
	end
if update(RFIType)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'RFIType', d.RFIType, i.RFIType,
			SUSER_SNAME(), 'RFI Type has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RFIType,'') <> isnull(i.RFIType,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.RFIType, d.RFIType
	end
if update(RFI)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C', 'RFI', d.RFI, i.RFI,
			SUSER_SNAME(), 'RFI has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType and d.PCO=i.PCO and d.PCOItem=i.PCOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RFI,'') <> isnull(i.RFI,'') and isnull(c.DocHistPCO,'N') = 'Y'
	and i.PCOItem is not null and i.ACOItem is null
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.RFI, d.RFI
	end




ACO_side:
---- ACO side
if not exists(select top 1 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and isnull(c.DocHistACO,'N') = 'Y')
	begin
  	goto aco_side_end
	end

if update(Description)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'Description', d.Description, i.Description,
			SUSER_SNAME(), 'Description has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and isnull(c.DocHistACO,'N') = 'Y'
	and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.Description, d.Description
	end
if update(Units)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'Units', convert(varchar(16),d.Units), convert(varchar(16),i.Units),
			SUSER_SNAME(), 'Units have been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Units,'') <> isnull(i.Units,'') and isnull(c.DocHistACO,'N') = 'Y'
	and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.Units, d.Units
	end
if update(UnitPrice)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'UnitPrice', convert(varchar(16),d.UnitPrice), convert(varchar(16),i.UnitPrice),
			SUSER_SNAME(), 'Unit Price has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(convert(varchar(16),d.UnitPrice),'') <> isnull(convert(varchar(16),i.UnitPrice),'')
	and isnull(c.DocHistACO,'N') = 'Y' and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.UnitPrice, d.UnitPrice
	end
if update(UM)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'UM', d.UM, i.UM,
			SUSER_SNAME(), 'UM has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.UM,'') <> isnull(i.UM,'') and isnull(c.DocHistACO,'N') = 'Y'
	and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.UM, d.UM
	end
if update(ChangeDays)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'ChangeDays', convert(varchar(6),d.ChangeDays), convert(varchar(6),i.ChangeDays),
			SUSER_SNAME(), 'Change Days has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ChangeDays,'') <> isnull(i.ChangeDays,'') and isnull(c.DocHistACO,'N') = 'Y'
	and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.ChangeDays, d.ChangeDays
	end
if update(ForcePhaseYN)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'ForcePhaseYN', d.ForcePhaseYN, i.ForcePhaseYN,
			SUSER_SNAME(), 'Force Phase flag has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ForcePhaseYN,'') <> isnull(i.ForcePhaseYN,'') and isnull(c.DocHistACO,'N') = 'Y'
	and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.ForcePhaseYN, d.ForcePhaseYN
	end
if update(ContractItem)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'ContractItem', d.ContractItem, i.ContractItem,
			SUSER_SNAME(), 'Contract Item has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ContractItem,'') <> isnull(i.ContractItem,'') and isnull(c.DocHistACO,'N') = 'Y'
	and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.ContractItem, d.ContractItem
	end

if update(BillGroup)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'BillGroup', d.BillGroup, i.BillGroup,
			SUSER_SNAME(), 'Bill Group has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.BillGroup,'') <> isnull(i.BillGroup,'') and isnull(c.DocHistACO,'N') = 'Y'
	and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.BillGroup, d.BillGroup
	end
if update(Approved)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'Approved', d.Approved, i.Approved,
			SUSER_SNAME(), 'Approved flag has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Approved,'') <> isnull(i.Approved,'') and isnull(c.DocHistACO,'N') = 'Y'
	and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.Approved, d.Approved
	end
if update(ApprovedAmt)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'ApprovedAmt', convert(varchar(16),d.ApprovedAmt), convert(varchar(16),i.ApprovedAmt),
			SUSER_SNAME(), 'Approved Amt has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(convert(varchar(16),d.ApprovedAmt),'') <> isnull(convert(varchar(16),i.ApprovedAmt),'')
	and isnull(c.DocHistACO,'N') = 'Y' and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.ApprovedAmt, d.ApprovedAmt
	end
if update(Status)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'Status', d.Status, i.Status,
			SUSER_SNAME(), 'Status has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and isnull(c.DocHistACO,'N') = 'Y'
	and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.Status, d.Status
	end
if update(ApprovedDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'ApprovedDate', convert(char(8),d.ApprovedDate,1),
			convert(char(8),i.ApprovedDate,1), SUSER_SNAME(), 'Approved Date has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ApprovedDate,'') <> isnull(i.ApprovedDate,'')
	and isnull(c.DocHistACO,'N') = 'Y' and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.ApprovedDate, d.ApprovedDate
	end
if update(BudgetNo)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, ACOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'BudgetNo', d.BudgetNo, i.BudgetNo,
			SUSER_SNAME(), 'Budget No. has been changed', i.ACOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO and d.ACOItem=i.ACOItem
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.BudgetNo,'') <> isnull(i.BudgetNo,'')
	and isnull(c.DocHistACO,'N') = 'Y' and i.ACOItem is not null
	group by i.PMCo, i.Project, i.ACO, i.ACOItem, i.BudgetNo, d.BudgetNo
	end


aco_side_end:

---- possible we are unapproving a PCO item from an ACO item.
---- if this is the case we may need to remove the PCO/ACO link if only occurrance
---- of the PCO for the ACO is the one being unapproved
---- record side TK-06121
IF UPDATE(ACO)
	BEGIN
	DELETE FROM dbo.vPMRelateRecord
	FROM INSERTED i
	INNER JOIN DELETED d ON d.KeyID = i.KeyID
	INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
	INNER JOIN dbo.bPMOP h ON h.PMCo=d.PMCo AND h.Project=d.Project AND h.PCOType=d.PCOType AND h.PCO=d.PCO
	INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=c.KeyID AND a.LinkTableName='PMOP' AND a.LINKID=h.KeyID
	WHERE d.ACO IS NOT NULL AND i.ACO IS NULL AND i.PCO IS NOT null
	AND (SELECT COUNT(*) FROM dbo.bPMOI x WHERE x.PMCo=i.PMCo AND x.Project=i.Project 
					AND x.PCOType=i.PCOType AND x.PCO=i.PCO 
					AND x.ACO=d.ACO AND x.KeyID <> i.KeyID) = 0
					
	---- link side
	DELETE FROM dbo.vPMRelateRecord
	FROM INSERTED i
	INNER JOIN DELETED d ON d.KeyID = i.KeyID
	INNER JOIN dbo.bPMOH c ON c.PMCo=d.PMCo AND c.Project=d.Project AND c.ACO=d.ACO
	INNER JOIN dbo.bPMOP h ON h.PMCo=d.PMCo AND h.Project=d.Project AND h.PCOType=d.PCOType AND h.PCO=d.PCO
	INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOP' AND a.RECID=h.KeyID AND a.LinkTableName='PMOH' AND a.LINKID=c.KeyID
	WHERE d.ACO IS NOT NULL AND i.ACO IS NULL AND i.PCO IS NOT NULL
	AND (SELECT COUNT(*) FROM dbo.bPMOI x WHERE x.PMCo=i.PMCo AND x.Project=i.Project 
					AND x.PCOType=i.PCOType AND x.PCO=i.PCO 
					AND x.ACO=d.ACO AND x.KeyID <> i.KeyID) = 0

	---- insert vPMRelateRecord to link PCO/ACO TK-04303
	---- PCO and ACO
	INSERT INTO dbo.vPMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
	SELECT DISTINCT 'PMOH', a.KeyID, 'PMOP', b.KeyID
	FROM inserted i
	INNER JOIN DELETED d ON d.KeyID = i.KeyID
	INNER JOIN dbo.bPMOH a ON a.PMCo=i.PMCo AND a.Project=i.Project AND a.ACO=i.ACO
	INNER JOIN dbo.bPMOP b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.PCOType=i.PCOType AND b.PCO=i.PCO
	WHERE i.ACO IS NOT NULL AND i.PCO IS NOT NULL AND d.ACO IS NULL
	AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMOH' AND c.RECID=a.KeyID
					AND c.LinkTableName='PMOP' AND c.LINKID=b.KeyID)
	AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord d WHERE d.RecTableName='PMOP' AND d.RECID=b.KeyID
					AND d.LinkTableName='PMOH' AND d.LINKID=a.KeyID)
	END


return


error:
   	if @opencursor = 1
   		begin
   		close bPMOI_insert
   		deallocate bPMOI_insert
   		set @opencursor = 0
   		end

	select @errmsg = isnull(@errmsg,'') + ' - cannot update into PMOI'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
  
 





























GO
ALTER TABLE [dbo].[bPMOI] WITH NOCHECK ADD CONSTRAINT [CK_bPMOI_PCO] CHECK (([PCO] IS NULL OR [PCOType] IS NOT NULL))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMOI] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPMOIPCOType] ON [dbo].[bPMOI] ([PCOType], [PMCo], [Project]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPMOI_PMCOContract] ON [dbo].[bPMOI] ([PMCo], [Contract], [Project]) INCLUDE ([ApprovedAmt]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMOI] ON [dbo].[bPMOI] ([PMCo], [Project], [PCOType], [PCO], [PCOItem], [ACO], [ACOItem]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPMOIStatus] ON [dbo].[bPMOI] ([Status], [PMCo], [Project]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMOI] WITH NOCHECK ADD CONSTRAINT [FK_bPMOI_bPMDT] FOREIGN KEY ([PCOType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[bPMOI] WITH NOCHECK ADD CONSTRAINT [FK_bPMOI_bJCCI] FOREIGN KEY ([PMCo], [Contract], [ContractItem]) REFERENCES [dbo].[bJCCI] ([JCCo], [Contract], [Item])
GO
ALTER TABLE [dbo].[bPMOI] WITH NOCHECK ADD CONSTRAINT [FK_bPMOI_bPMOH] FOREIGN KEY ([PMCo], [Project], [ACO]) REFERENCES [dbo].[bPMOH] ([PMCo], [Project], [ACO])
GO
ALTER TABLE [dbo].[bPMOI] WITH NOCHECK ADD CONSTRAINT [FK_bPMOI_bPMOP] FOREIGN KEY ([PMCo], [Project], [PCOType], [PCO]) REFERENCES [dbo].[bPMOP] ([PMCo], [Project], [PCOType], [PCO])
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPMOI].[Units]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPMOI].[UnitPrice]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMOI].[Approved]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPMOI].[Approved]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMOI].[ForcePhaseYN]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPMOI].[ForcePhaseYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMOI].[FixedAmountYN]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPMOI].[FixedAmountYN]'
GO
