CREATE TABLE [dbo].[bPRTB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[PostSeq] [smallint] NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[DayNum] [smallint] NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[EMCo] [dbo].[bCompany] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[EquipCType] [dbo].[bJCCType] NULL,
[UsageUnits] [dbo].[bHrs] NULL,
[TaxState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[LocalCode] [dbo].[bLocalCode] NULL,
[UnempState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[InsState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[InsCode] [dbo].[bInsCode] NULL,
[PRDept] [dbo].[bDept] NOT NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Cert] [dbo].[bYN] NOT NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[Shift] [tinyint] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[OldEmployee] [dbo].[bEmployee] NULL,
[OldPaySeq] [tinyint] NULL,
[OldPostSeq] [smallint] NULL,
[OldType] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldPostDate] [dbo].[bDate] NULL,
[OldJCCo] [dbo].[bCompany] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldPhaseGroup] [dbo].[bGroup] NULL,
[OldPhase] [dbo].[bPhase] NULL,
[OldGLCo] [dbo].[bCompany] NULL,
[OldEMCo] [dbo].[bCompany] NULL,
[OldWO] [dbo].[bWO] NULL,
[OldWOItem] [dbo].[bItem] NULL,
[OldEquipment] [dbo].[bEquip] NULL,
[OldEMGroup] [dbo].[bGroup] NULL,
[OldCostCode] [dbo].[bCostCode] NULL,
[OldCompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldComponent] [dbo].[bEquip] NULL,
[OldRevCode] [dbo].[bRevCode] NULL,
[OldEquipCType] [dbo].[bJCCType] NULL,
[OldUsageUnits] [dbo].[bHrs] NULL,
[OldTaxState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OldLocalCode] [dbo].[bLocalCode] NULL,
[OldUnempState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OldInsState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OldInsCode] [dbo].[bInsCode] NULL,
[OldPRDept] [dbo].[bDept] NULL,
[OldCrew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldCert] [dbo].[bYN] NULL,
[OldCraft] [dbo].[bCraft] NULL,
[OldClass] [dbo].[bClass] NULL,
[OldEarnCode] [dbo].[bEDLCode] NULL,
[OldShift] [tinyint] NULL,
[OldHours] [dbo].[bHrs] NULL,
[OldRate] [dbo].[bUnitCost] NULL,
[OldAmt] [dbo].[bDollar] NULL,
[Memo] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[OldMemo] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[EquipPhase] [dbo].[bPhase] NULL,
[OldEquipPhase] [dbo].[bPhase] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[SMScope] [int] NULL,
[SMPayType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldSMCo] [dbo].[bCompany] NULL,
[OldSMWorkOrder] [int] NULL,
[OldSMScope] [int] NULL,
[OldSMPayType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SMCostType] [smallint] NULL,
[OldSMCostType] [smallint] NULL,
[SMJCCostType] [dbo].[bJCCType] NULL,
[OldSMJCCostType] [dbo].[bJCCType] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPRTBd    Script Date: 8/28/99 9:38:13 AM ******/
CREATE     TRIGGER [dbo].[btPRTBd] on [dbo].[bPRTB] for DELETE as     

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), 
           @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Update trigger for PRTB
    *  Created By: kb
    *  Date: 2/25/98
    *  Made Better by TV 03/21/02- delete HQAT Records
    *                 bc 01/08/03 - delete the HQAT code
    *                         EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *                                                                   and corrected old style joins
    *                         EN 7/17/07 - issue 27873 added where clause to check InUseBatchId for null
      *                                               to resolve a delete error when clearing reversing entries from a batch
      *                             mh 05/14/09 - Issue 133439/127603
    *                         ECV 02/04/11 - Issue 131640 Delete or updated the associated SM Work Completed record and
    *                                                 delete the SMBC record that links them.
    *                   ECV 06/30/11 - Added check for SM UsePRInterface flag
    *                         CJG 07/16/12 - D-05239 - Ensure SM Work Completed is deleted if not billed.
    *                   JayR 11/16/2012 TK-16638.  Change how the join is done to bPRTH so deadlocks do not occur.
    *                   JayR 12/04/2012 TK-16638.  Slight change in logic to make sure PRTBKeyId in PRTH is cleared.
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
   
      set nocount on
                   
      /* Flag to print debug statements */
      DECLARE @PrintDebug bit
      Set @PrintDebug=0

      --select @validcnt2 = count(1) from deleted d 
      --join dbo.bPRTH h with (nolock) on d.Co=h.PRCo and d.Employee=h.Employee and d.PaySeq=h.PaySeq
      --    and d.PostSeq=h.PostSeq
      --join dbo.bHQBC c with (nolock) on c.Co=d.Co and c.Mth=d.Mth and c.BatchId=d.BatchId
      --    and c.PRGroup=h.PRGroup and c.PREndDate=h.PREndDate
      --where h.InUseBatchId is not null
      select @validcnt2 = count(*) from deleted d 
      join dbo.bPRTH h with (nolock) on d.KeyID = h.PRTBKeyID
      
      update dbo.bPRTH
      set InUseBatchId=null 
        , PRTBKeyID=null
      from dbo.bPRTH h with (nolock)
      join deleted d on d.KeyID = h.PRTBKeyID

      if convert(int,@@rowcount) <> convert(int,@validcnt2)
      begin
            select @errmsg = 'Unable to remove InUse Flag from PR Timecard Header.'
            goto error
      end
   
      -- Delete attachments if they exist. Make sure UniqueAttchID is not null.
      insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
      select AttachmentID, suser_name(), 'Y' 
      from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
      where h.UniqueAttchID not in(select t.UniqueAttchID from bPRTH t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
      and d.UniqueAttchID is not null     

      -- Issue 131640 Update or delete the associated SM Work Completed record and delete the SMBC link
      IF EXISTS(Select 1 from DELETED 
                        INNER JOIN vSMBC ON vSMBC.PostingCo = DELETED.Co AND vSMBC.InUseMth=DELETED.Mth
                              AND vSMBC.InUseBatchId = DELETED.BatchId AND vSMBC.InUseBatchSeq=DELETED.BatchSeq
                        WHERE DELETED.Type='S' AND vSMBC.Source='PRTimecard' AND vSMBC.UpdateInProgress=0)
      BEGIN
            -- Delete any linked SMWorkCompleted records that have not been invoiced.
            DECLARE @SMWorkCompletedID int, @SMWorkCompletedStatus varchar(11)
            DECLARE @SMWorkCompleted TABLE (SMWorkCompletedID int, [Status] varchar(11))
            INSERT INTO @SMWorkCompleted (SMWorkCompletedID)
                  SELECT SMWorkCompletedID FROM SMWorkCompleted
                  LEFT JOIN SMInvoice ON SMInvoice.SMCo=SMWorkCompleted.SMCo AND SMInvoice.SMInvoiceID=SMWorkCompleted.SMInvoiceID
                  WHERE SMInvoice.SMInvoiceID IS NULL AND SMWorkCompletedID IN (
                        SELECT vSMBC.SMWorkCompletedID FROM vSMBC
                        INNER JOIN DELETED ON DELETED.Type='S' AND vSMBC.PostingCo = DELETED.Co AND vSMBC.InUseMth=DELETED.Mth
                              AND vSMBC.InUseBatchId = DELETED.BatchId AND vSMBC.InUseBatchSeq=DELETED.BatchSeq
                        WHERE vSMBC.Source='PRTimecard' AND vSMBC.UpdateInProgress=0
                        )

            DECLARE idcursor CURSOR FOR
            SELECT SMWorkCompletedID FROM @SMWorkCompleted
            
            OPEN idcursor
            FETCH NEXT FROM idcursor INTO @SMWorkCompletedID
            WHILE @@FETCH_STATUS = 0
            BEGIN
IF (@PrintDebug=1) PRINT 'btPRTBd 1: Deleting SMWorkCompleted'
            
                  BEGIN TRY
                        UPDATE vSMBC Set UpdateInProgress=1 WHERE SMWorkCompletedID=@SMWorkCompletedID
                        BEGIN TRY
                              DELETE SMWorkCompleted WHERE SMWorkCompletedID = @SMWorkCompletedID
                        END TRY
                        
                        BEGIN CATCH
                              UPDATE vSMBC Set UpdateInProgress=0 WHERE SMWorkCompletedID=@SMWorkCompletedID
                              SELECT @errmsg = ERROR_MESSAGE()
                              GOTO error
                        END CATCH
                        DELETE vSMBC WHERE SMWorkCompletedID=@SMWorkCompletedID
                  END TRY
                  BEGIN CATCH
                        SELECT @errmsg = ERROR_MESSAGE()
                        GOTO error
                  END CATCH

                  FETCH NEXT FROM idcursor INTO @SMWorkCompletedID
            END
            CLOSE idcursor
            DEALLOCATE idcursor
            
            -- Clear out the list SMWorkCompletedIDs
            DELETE FROM @SMWorkCompleted

            INSERT INTO @SMWorkCompleted (SMWorkCompletedID, [Status])
                  SELECT SMWorkCompletedID, [Status] FROM SMWorkCompleted
                  LEFT JOIN SMInvoice ON SMInvoice.SMCo=SMWorkCompleted.SMCo AND SMInvoice.SMInvoiceID=SMWorkCompleted.SMInvoiceID
                  WHERE NOT SMInvoice.SMInvoiceID IS NULL AND SMWorkCompletedID IN (
                        SELECT vSMBC.SMWorkCompletedID FROM vSMBC
                        INNER JOIN DELETED ON DELETED.Type='S' AND vSMBC.PostingCo = DELETED.Co AND vSMBC.InUseMth=DELETED.Mth
                              AND vSMBC.InUseBatchId = DELETED.BatchId AND vSMBC.InUseBatchSeq=DELETED.BatchSeq
                        WHERE vSMBC.Source='PRTimecard' AND vSMBC.UpdateInProgress=0
                        )
                        
            DECLARE idcursor CURSOR FOR
            SELECT SMWorkCompletedID, [Status] FROM @SMWorkCompleted
            
            OPEN idcursor
            FETCH NEXT FROM idcursor INTO @SMWorkCompletedID, @SMWorkCompletedStatus
            WHILE @@FETCH_STATUS = 0
            BEGIN
                  BEGIN TRY
                        UPDATE vSMBC Set UpdateInProgress=1 WHERE SMWorkCompletedID=@SMWorkCompletedID
                        BEGIN TRY
                        -- Set the CostQty and ProjCost to zero for any linked SMWorkCompleted records that have been invoiced.
IF (@PrintDebug=1) PRINT 'btPRTBd 2: Updating SMWorkCompleted to zero if billed'
                              UPDATE vSMWorkCompletedLabor SET CostQuantity=0, ProjCost=0 
                                    WHERE SMWorkCompletedID = @SMWorkCompletedID 
                                      AND @SMWorkCompletedStatus = 'Billed'
IF (@PrintDebug=1) PRINT 'btPRTBd 2: Delete SMWorkCompleted if not billed'                      
                              DELETE FROM vSMWorkCompletedLabor
                                    WHERE SMWorkCompletedID = @SMWorkCompletedID 
                                      AND @SMWorkCompletedStatus <> 'Billed'
                        END TRY
                        BEGIN CATCH
                              UPDATE vSMBC Set UpdateInProgress=0 WHERE SMWorkCompletedID=@SMWorkCompletedID
                              SELECT @errmsg = ERROR_MESSAGE()
                              GOTO error
                        END CATCH
                  END TRY
                  BEGIN CATCH
                        SELECT @errmsg = ERROR_MESSAGE()
                        GOTO error
                  END CATCH
                  -- Delete the SMBC records that link the SMWorkCompleted to the PRTB records.
IF (@PrintDebug=1) PRINT 'btPRTBd 3: Deleting SMBC'
                  DELETE vSMBC WHERE SMWorkCompletedID=@SMWorkCompletedID
                  
                  FETCH NEXT FROM idcursor INTO @SMWorkCompletedID, @SMWorkCompletedStatus
            END
            CLOSE idcursor
            DEALLOCATE idcursor
      END
      -- Issue 131640 End

   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot remove PRTB'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPRTBi    Script Date: 8/28/99 9:38:14 AM ******/
       CREATE               trigger [dbo].[btPRTBi] on [dbo].[bPRTB] for INSERT as
/*--------------------------------------------------------------
        *  Created:  kb 2/25/98
        *  Modified: kb 7/27/98
        *            danf 02/16/2000 - Added crew update to PREH and inhabitied Nontrue earnings from update Job in PREH
        *            danf 04/11/2000 - Added Join validation on the update of PREH for crews and jobs.
        *            GG 05/05/00 - Added usage entries for Equipment Attachments
        *            GG 06/20/01 - set bPREH.AuditYN = 'N' when updating LastJob or Crew to avoid HQ auditing
        *	         GG 08/02/01 - issue 14083 - update EMEM last job
        *	         GG 10/23/01 - issue 15020 - update valid jobs only to bEMEM
        *			 EN 01/29/02 - issue 16023 - set AuditYN/UpdateYN flags back to 'Y' when done updating bPREH/bEMEM
        *			 GG 03/01/02 - update PREH and EMEM only when necessary 
        *			 EN 03/11/02 - issue 14181 Include new EquipPhase field when automatically post equipment attachments to batch
        *			 EN 03/26/02 - issue 14180 Use equip cost type override in equipment attachments rather than using usage cost type set up in bEMEM for the attachment
        *			 EN 08/27/02 - issue 16942 insert reversing entries as BatchTransType 'R' to avoid updating 'Last' values and adding equipment attachment postings
    	*			 EN 08/15/03 - issue 21505 update job to bEMEM only for Type 'J' timecards
        *			 DANF 08/19/03 - issue 22224 performance improvements
    	*			 EN 02/19/03 - issue 23061  added isnull check, and dbo
    	*			 TV 03/11/04 - issue 24032 - Needs to check JobUpdate Flag
   		*			 TV 04/14/04 - issue 23255 Moved EMEM Update to Batch Processing 
		*			 EN 09/27/06 - issue 27801 - Addition to issue 16023 fix to ensure that AuditYN does not get stuck as 'N' during Job/Crew update in case of trigger error
       	*			 EN 03/13/07 - issue 123924 - verify that JCCo, Job, or Crew has changed before updating PREH
		*			 EN 05/19/08 - issue 127867  update PREH_LastUpdated when timecards are posted with job and/or crew regardless of whether the job/crew fields are updated in PREH
		*			 EN 06/08/09 - issue 132027  resolve performance issues
		*			 EN 05/28/10 - issue 139254  Added validation for situation where amount is zero but rate * hours is non-zero
		*			ECV 02/03/11 - Issue 131640  Add insert to SMWorkCompleted table
		*			ECV 03/15/11 - Added Craft,Class, Shift update to SMWorkCompleted
        *           ECV 06/30/11 - Added check for SM UsePRInterface flag
        *			JJB 07/05/11 - Quick fix to the cursor used in the SM UsePRInteface flag change above.
        *           ECV 08/25/11 - Add update of SMCostType.
        *           JG  02/09/12 - TK-12388 - Add update of SMJCCostType and SMPhaseGroup.
        *			ECV 06/07/12 TK-14637 removed SMPhaseGroup. Use PhaseGroup instead.
		*           JayR 10/15/2012 TK-16099 Fix overlapping variables.
		*           JayR 12/03/2012 TK-19841  This should fix an issue where PRTBKeyId was not getting set.  This should also prevent deadlocks on loading bPRTB with data.
		*           JayR 12/04/2012 TK-19841  Fix some slight logic bugs in setting and clearing of InUseBatchId and PRTBKeyId.
        *  Insert trigger for PR Timecard Batch table
        *
        *--------------------------------------------------------------*/
		/* Flag to print debug statements */
		DECLARE @PrintDebug bit
		Set @PrintDebug=0
        
		declare @numrows int, @errmsg varchar(255), @validcnt int, @opencursor tinyint, @SM_opencursor tinyint
        
		-- PRTB declares
		declare @co bCompany, @mth bMonth, @batchid bBatchID, @employee bEmployee, @payseq tinyint, @daynum smallint,
			@postdate bDate, @jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @glco bCompany, @emco bCompany,
			@equip bEquip, @emgroup bGroup, @revcode bRevCode, @usageunits bHrs, @taxstate varchar(4), @localcode bLocalCode,
			@unempstate varchar(4), @insstate varchar(4), @inscode bInsCode, @prdept bDept, @crew varchar(10), @cert bYN,
			@craft_lower bCraft, @class bClass, @earncode bEDLCode, @shift tinyint, @seq int, @equipphase bPhase, 
			@SMCo bCompany, @SMWorkOrder int, @SMScope int, @SMPayType varchar(10), @SMCostType smallint, @Hours bHrs, @rcode int, @batchseq int,
			@Craft bCraft, @Class bClass, @Shift TINYINT, @SMJCCostType dbo.bJCCType
        
		declare @attachment bEquip, @attachpostrev bYN, @equipctype bJCCType
        
		select @numrows = @@rowcount
		if @numrows = 0 return
		SET NOCOUNT ON
		
		-- make sure we're inserting into an open PR Batch (revised for #132027)
		IF EXISTS(select top 1 1 from inserted i
			JOIN dbo.bHQBC b with (nolock) on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId
			WHERE (b.PRGroup is null or b.PREndDate is null or b.Status <> 0))
		BEGIN
			SELECT @errmsg = 'Must reference an open Payroll Batch '
			GOTO error
		END
		
		--#139254 Check for Non-Zero Rate and Hours with Zero Amount (this does not resolve issue ... for troubleshooting)
		IF EXISTS(SELECT 1 FROM Inserted Ins 
			JOIN dbo.PREC ON Ins.EarnCode = PREC.EarnCode AND Ins.Co = PREC.PRCo
			WHERE PREC.Method = 'H' AND Ins.Amt = 0.00 AND ROUND(Ins.Hours * Ins.Rate, 2) <> 0.00)
		BEGIN
			SELECT @errmsg = 'Detected timecard with rate and hours but amount of zero.  Please contact Viewpoint support.'
			GOTO error
		END
		
		-- get total # of 'change' and 'delete' entries
		select @validcnt = count(*) from inserted where (BatchTransType = 'C' or BatchTransType = 'D') /*issue 16942*/
		
		-- lock existing Timecards 'pulled' into batch
		-- In order to prevent deadlocking we are getting the IDs in a select statement with a nolock.  
		DECLARE @ttPRTH TABLE
		(
            PRTBKeyID BIGINT
            , PRTHKeyID BIGINT
            , BatchId bBatchID
		);

		  INSERT INTO @ttPRTH
		  (PRTBKeyID, PRTHKeyID, BatchId)
		  SELECT i.KeyID, bPRTH.KeyID, i.BatchId
		  from inserted i WITH (NOLOCK)  
		  join bHQBC c WITH (NOLOCK) 
				  on c.Co = i.Co and c.Mth = i.Mth and c.BatchId = i.BatchId 
		  join bPRTH with (NOLOCK) 
				  on bPRTH.PRCo = c.Co 
				  and bPRTH.PRGroup = c.PRGroup 
				  and bPRTH.PREndDate = c.PREndDate 
				  and bPRTH.PRCo = i.Co 
				  and bPRTH.Employee = i.Employee 
				  and bPRTH.PaySeq = i.PaySeq 
				  and bPRTH.PostSeq = i.PostSeq 
		  where (i.BatchTransType = 'C' or i.BatchTransType = 'D')
		  AND (bPRTH.PRTBKeyID IS NULL OR bPRTH.InUseBatchId IS NULL)
      
		  UPDATE bPRTH
		  SET PRTBKeyID = t.PRTBKeyID
		    , InUseBatchId = t.BatchId
		  FROM @ttPRTH t 
		  WHERE bPRTH.KeyID = t.PRTHKeyID
		  AND (bPRTH.PRTBKeyID IS NULL OR bPRTH.InUseBatchId IS NULL)

		if @@rowcount <> @validcnt
		begin
			select @errmsg = 'Unable to flag Timecard Header as ''In Use''.'
			goto error
		end

		if exists(select top 1 1 from inserted i where i.BatchTransType = 'A')
		begin -- if exists( #6 - if any record in inserted has a Batch Transaction Type of Add then preform updates below.
			-- Update PREH if needed
			-- #127867 enclosed code in Job/Crew not null condition
			if exists(select 1 from inserted where Job is not null or Crew is not null)
			begin -- if exists( #5
				-- update 'Last Job' in Employee Header if changed since last date PREH was updated
				if exists(select 1 from inserted where Job is not null)
				begin -- if exists( #4
					update dbo.bPREH
					set JCCo = i.JCCo, Job = i.Job, AuditYN = 'N'    -- avoid HQMA auditing
					from dbo.bPREH r with (nolock) 
					join inserted i on i.Co = r.PRCo and i.Employee = r.Employee
					join dbo.bJCJM j  with (nolock) on i.JCCo = j.JCCo and i.Job = j.Job       -- must be an existing Job
					where i.BatchTransType = 'A' and (i.PostDate >= r.LastUpdated or r.LastUpdated is null)
					and (isnull(r.JCCo,'') <> isnull(i.JCCo,'') or isnull(r.Job,'') <> isnull(i.Job,''))	-- check if job is different
				end -- if exists( #4
				
				-- update 'Last Crew' in Employee Header if changed since last date PREH was updated
				if exists(select 1 from inserted where Crew is not null)
				begin -- if exists( #3
					update dbo.bPREH
					set Crew = i.Crew, AuditYN = 'N'    -- avoid HQMA auditing
					from dbo.bPREH r with (nolock) 
					join inserted i on i.Co = r.PRCo and i.Employee = r.Employee
					join dbo.bPRCR c with (nolock) on i.Co = c.PRCo and i.Crew = c.Crew           -- must be a valid Crew
					where i.BatchTransType = 'A' and (i.PostDate >= r.LastUpdated or r.LastUpdated is null)
					and isnull(r.Crew,'') <> isnull(i.Crew,'')		-- add crew check
				end -- if exists( #3
				
				-- #127867 set Last Updated date whether or not Job or Crew was actually updated
				update dbo.bPREH
				set LastUpdated = i.PostDate
				from dbo.bPREH r with (nolock) 
				join inserted i on i.Co = r.PRCo and i.Employee = r.Employee
				where i.BatchTransType = 'A' and (i.PostDate > r.LastUpdated or r.LastUpdated is null)
				
				-- issue 16023 fix for rejection - change bPREH AuditYN values back to 'Y' after updating job or crew
				update dbo.bPREH
				set AuditYN = 'Y'
				from dbo.bPREH r with (nolock) 
				join inserted i on i.Co = r.PRCo and i.Employee = r.Employee
				where i.BatchTransType = 'A'
				and isnull(r.AuditYN,'') = 'N'	-- check if AuditYN is not 'Y'
			end -- if exists( #5

			-- check for new Timecards posted with Equipment Usage
			if exists(select * from inserted where BatchTransType = 'A' and Equipment is not null and RevCode is not null)
			begin -- if exists( #1
				-- Auto add Equipment Usage entries for attachments
				if @numrows = 1
					select @co = Co, @mth = Mth, @batchid = BatchId, @employee = Employee, @payseq = PaySeq, @daynum = DayNum,
						@postdate = PostDate, @jcco = JCCo, @job = Job, @phasegroup = PhaseGroup, @phase = Phase, @glco = GLCo,
						@emco = EMCo, @equip = Equipment, @emgroup = EMGroup, @revcode = RevCode, @usageunits = UsageUnits,
						@taxstate = TaxState, @localcode = LocalCode, @unempstate = UnempState, @insstate = InsState,
						@inscode = InsCode, @prdept = PRDept, @crew = Crew, @cert = Cert, @craft_lower = Craft, @class = Class,
						@earncode = EarnCode, @shift = Shift, @equipphase = EquipPhase, @equipctype = EquipCType
					from inserted
				else
				begin -- else
					-- use a cursor to process each inserted row
					declare bPRTB_insert cursor local fast_forward for
					select Co, Mth, BatchId, Employee, PaySeq, DayNum, PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo,
						Equipment, EMGroup, RevCode, UsageUnits, TaxState, LocalCode, UnempState, InsState, InsCode, PRDept,
						Crew, Cert, Craft, Class, EarnCode, Shift, EquipPhase, EquipCType
					from inserted
					where BatchTransType = 'A' and Equipment is not null and RevCode is not null
					
					open bPRTB_insert
					select @opencursor = 1  -- open cursor flag
					
					fetch next from bPRTB_insert into @co, @mth, @batchid, @employee, @payseq, @daynum, @postdate, @jcco, @job,
						@phasegroup, @phase, @glco, @emco, @equip, @emgroup, @revcode, @usageunits, @taxstate,
						@localcode, @unempstate, @insstate, @inscode, @prdept, @crew, @cert, @craft_lower, @class, @earncode, @shift,
						@equipphase, @equipctype
					if @@fetch_status <> 0
					begin
						select @errmsg = 'Cursor error'
						goto error
					end
				end -- else
				
				attachment_check:
				-- check for Equipment Attachments
				if exists(select top 1 1 from dbo.bEMEM  with (nolock) where EMCo = @emco and AttachToEquip = @equip and Status = 'A') --revised for #132027
				begin -- if exists( #2
					select @seq = max(BatchSeq)
					from inserted i  where i.Co = @co and i.Mth = @mth and i.BatchId = @batchid
    
					-- get first Attachment
					select @attachment = min(Equipment)
					from dbo.bEMEM  with (nolock) where EMCo = @emco and AttachToEquip = @equip and Status = 'A'
					-- if posting revenue to Attachment - add a timecard
					while @attachment is not null
					begin -- while @attachment is not null
						select @attachpostrev = null
						select @attachpostrev = AttachPostRevenue
						from dbo.bEMEM with (nolock) 
						where EMCo = @emco and Equipment = @attachment
						if @attachpostrev = 'Y'
						begin -- if @attachpostrev = 'Y'
							select @seq = @seq + 1
							insert into dbo.bPRTB (Co, Mth, BatchId, BatchSeq, BatchTransType, Employee, PaySeq, Type, DayNum,
								PostDate, JCCo, Job, PhaseGroup, Phase, GLCo, EMCo, Equipment, EMGroup, RevCode, EquipCType,
								UsageUnits, TaxState, LocalCode, UnempState, InsState, InsCode, PRDept, Crew, Cert, Craft,
								Class, EarnCode, Shift, Hours, Rate, Amt, EquipPhase)
							values(@co, @mth, @batchid, @seq, 'A', @employee, @payseq, 'J', @daynum,
								@postdate, @jcco, @job, @phasegroup, @phase, @glco, @emco, @attachment, @emgroup, @revcode,
								@equipctype, @usageunits, @taxstate, @localcode, @unempstate, @insstate, @inscode, @prdept,
								@crew, @cert, @craft_lower, @class, @earncode, @shift, 0,0,0, @equipphase)
						end -- if @attachpostrev = 'Y'
						-- get next Attachment
						select @attachment = min(Equipment)
						from dbo.bEMEM with (nolock) 
						where EMCo = @emco and AttachToEquip = @equip and Status = 'A' and Equipment > @attachment
					end -- while @attachment is not null
				end -- if exists( #2
				
				if @opencursor = 1
				begin --@opencursor = 1
					fetch next from bPRTB_insert into @co, @mth, @batchid, @employee, @payseq, @daynum, @postdate,
						@jcco, @job, @phasegroup, @phase, @glco, @emco, @equip, @emgroup, @revcode, @usageunits,
						@taxstate, @localcode, @unempstate, @insstate, @inscode, @prdept, @crew, @cert, @craft_lower,
						@class, @earncode, @shift, @equipphase, @equipctype
					if @@fetch_status = 0
      					goto attachment_check
      				else
      				begin
      					close bPRTB_insert
      					deallocate bPRTB_insert
						select @opencursor = 0
      				end
      			end --@opencursor = 1
			end -- if exists( #1
			
			/*	Issue 131640
				Update SMWorkCompleted 
				Loop through the Inserted records that have a type of SM
			*/
			IF EXISTS(Select TOP 1 1 from inserted where inserted.Type='S')
			BEGIN
				declare SM_bPRTB_insert cursor local fast_forward for
				select inserted.Co, inserted.Mth, inserted.BatchId, inserted.Employee, inserted.BatchSeq, inserted.PostDate, inserted.SMCo, inserted.SMWorkOrder, inserted.SMScope, inserted.SMPayType, inserted.SMCostType, inserted.Hours, inserted.Craft, inserted.Class, inserted.Shift,
				inserted.SMJCCostType,inserted.PhaseGroup
				from inserted
				where BatchTransType = 'A' AND Type='S' 
				
				open SM_bPRTB_insert
				select @SM_opencursor = 1  -- open cursor flag
				
				fetch next from SM_bPRTB_insert into @co, @mth, @batchid, @employee, @batchseq, @postdate, 
				@SMCo, @SMWorkOrder, @SMScope, @SMPayType, @SMCostType, @Hours, @Craft, @Class, @Shift,
				@SMJCCostType, @phasegroup
				while @@fetch_status = 0
				begin
					BEGIN TRY
						-- This Stored Procedure will only create the link and Work Completed record if the link doesn't already exist.
						exec @rcode = vspSMTimecardInsert @PRCo=@co, @Mth=@mth, @BatchId=@batchid, @BatchSeq=@batchseq, @Employee=@employee, @PostDate=@postdate, 
						@SMCo=@SMCo, @WorkOrder=@SMWorkOrder, @Scope=@SMScope, @PayType=@SMPayType, @SMCostType=@SMCostType, @Hours=@Hours, @Craft=@Craft, @Class=@Class, @Shift=@Shift,
						@SMJCCostType=@SMJCCostType, @SMPhaseGroup=@phasegroup,  
						@errmsg=@errmsg OUTPUT
						
						if @rcode=1
						BEGIN
							set @errmsg = 'Error creating SMWorkCompleted: ' + @errmsg
							goto error					
						END
					END TRY
					BEGIN CATCH
						BEGIN
							set @errmsg = 'Error creating SMWorkCompleted: ' +ERROR_MESSAGE()
							goto error					
						END
					END CATCH
					fetch next from SM_bPRTB_insert into @co, @mth, @batchid, @employee, @batchseq, @postdate, 
					@SMCo, @SMWorkOrder, @SMScope, @SMPayType, @SMCostType, @Hours, @Craft, @Class, @Shift,
					@SMJCCostType, @phasegroup
				end
				if @SM_opencursor = 1
				begin
					close SM_bPRTB_insert
					deallocate SM_bPRTB_insert
					set @SM_opencursor=0
				end
			END
		end -- if exists( #6 -- End where Batch Transaction Type = Add
		
		return
		
		error:
		if @opencursor = 1
		begin
			close bPRTB_insert
			deallocate bPRTB_insert
		end
		if @SM_opencursor = 1
		begin
			close SM_bPRTB_insert
			deallocate SM_bPRTB_insert
			set @SM_opencursor=0
		end
		
		select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Timecard Batch'
		RAISERROR(@errmsg, 11, -1);
		rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btPRTBu] on [dbo].[bPRTB] for UPDATE as
/*--------------------------------------------------------------
       *  Created: kb 3/4/98
       *  Modified: danf 04/10/00 Update trigger for PR Timecard batch
       *                          Last Job and Crew updates to bPREH made here so that new batch entries can use
       *                          these values for defaults.
       *              GG 06/01/01 - prevent change to key values on existing timecards
       *              GG 06/20/01 - set bPREH.AuditYN = 'N' when updating last Job or Crew to avoid HQ auditing
       *				GG 08/02/01 - #14083 - update EMEM last job
       *				GG 10/23/01 - #15020 - update valid jobs only to bEMEM
       *				EN 1/29/02 - #16023 - set AuditYN/UpdateYN flags back to 'Y' when done updating bPREH/bEMEM
       *				EN 3/21/02 - issue 16741 To save time, do not try to update last job in equip master for timecards with no equipment
       *				EN 8/27/02 issue 16942 allow for changing BatchTransType 'R' to 'A'
       *				EN 8/15/03 issue 21505 update job to bEMEM only for Type 'J' timecards
       *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
       *				TV 3/11/04 24032 - Needs to check JobUpdate Flag
       *				TV 04/14/04 23255 - Update EMEM Job, JobDate and DateLastUsed when Job Type
	   *				EN 9/27/06 27801 - Addition to issue 16023 fix to ensure that AuditYN does not get stuck as 'N' during Job/Crew update in case of trigger error
	   *				EN 3/13/07 123924 - verify that JCCo, Job, or Crew has changed before updating PREH
	   *				EN 5/19/08 #127867  update PREH_LastUpdated when timecards are posted with job and/or crew regardless of whether the job/crew fields are updated in PREH
	   *				EN 5/28/10 #139254  Added validation for situation where amount is zero but rate * hours is non-zero
       *				ECV 02/04/11 #131640 Add update to linked SMWorkCompleted records.
       *				ECV 03/15/11 Add Craft/Class/Shift update to SMWorkCompleted
       *                ERICV 05/04/11 Modified for one unique WorkCompleted for all types.
       *                ERICV 05/05/11 Added check for SM UsePRInterface flag
       *                EricV 08/25/11 Added update of SMCostType.
       *				JG	  02/09/12 - TK-12388 - Added SMJCCostType and SMPhaseGroup.
       *				EricV 05/09/12 TK-14817 Create/Update SM Work Completed when Hours=0 but Amt>0
       *				EricV 05/21/12 TK-15002 - SM Work Completed record must exist for any timecard record that has an SM Work order number.
       *				EricV 06/07/12 TK-14637 removed SMPhaseGroup. Use PhaseGroup instead.
       *
       *--------------------------------------------------------------*/
      declare @numrows int, @errmsg varchar(255), @validcnt int
      
      select @numrows = @@rowcount
      if @numrows = 0 return
      
      set nocount on

	/* Flag to print debug statements */
	  DECLARE @PrintDebug bit
	  Set @PrintDebug=0
      
      /* check for key changes */
      select @validcnt = count(*)
      from deleted d 
      join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
      if @numrows <> @validcnt
       	begin
       	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Batch Sequence #'
       	goto error
       	end
      
      -- check for invalid Transaction Type changes
      select @validcnt = count(*)
      from deleted d 
      join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
      where ((i.BatchTransType = 'A' and (i.BatchTransType = 'C' or i.BatchTransType = 'D')) /*issue 16942*/
          or (d.BatchTransType <> 'A' and d.BatchTransType = 'A'))
      if @validcnt <> 0
          begin
          select @errmsg = 'Invalid Transaction type change'
          goto error
          end
      
      -- check for Employee and Pay Seq changes to existing Timecards
      select @validcnt = count(*)
      from deleted d 
      join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
      where i.BatchTransType <> 'A' and (i.Employee <> d.Employee or i.PaySeq <> d.PaySeq)
      if @validcnt <> 0
          begin
          select @errmsg = 'Cannot change Employee or Pay Sequence on existing timecards'
          goto error
          end

	  --#139254 Check for Non-Zero Rate and Hours with Zero Amount (this does not resolve issue ... for troubleshooting)
	  IF EXISTS
	  (
	  SELECT 1 
	  FROM Inserted Ins 
		JOIN dbo.PREC ON Ins.EarnCode = PREC.EarnCode AND Ins.Co = PREC.PRCo
	  WHERE PREC.Method = 'H'
		AND Ins.Amt = 0.00
		AND ROUND(Ins.Hours * Ins.Rate, 2) <> 0.00
	  )
	  BEGIN
		SELECT @errmsg = 'Detected timecard with rate and hours but amount of zero.  Please contact Viewpoint support.'
		GOTO error
	  END

      
	  -- Update PREH if needed
	  -- #127867 added condition on only get into the PREH update code if there are updates other than deletes
      if exists(select 1 from inserted i where i.BatchTransType <> 'D')
    	begin
		-- #127867 only update PREH if Job/Crew not null
		if exists(select 1 from inserted where Job is not null or Crew is not null)
		  begin
		  -- update 'last job' in Employee Header
		  if exists(select 1 from inserted where Job is not null)
			  begin
			  update dbo.bPREH
			  set JCCo = i.JCCo, Job = i.Job, AuditYN = 'N'    -- to avoid HQMA auditing
			  from dbo.bPREH r
			  join inserted i on i.Co = r.PRCo and i.Employee = r.Employee
			  join dbo.bJCJM j with (nolock) on i.JCCo = j.JCCo and i.Job = j.Job   -- must be an existing Job
			  where i.BatchTransType <> 'D'   -- skip deletes
				  and (i.PostDate >= r.LastUpdated or r.LastUpdated is null) -- only if posting date is later
				  and (isnull(r.JCCo,'') <> isnull(i.JCCo,'') or isnull(r.Job,'') <> isnull(i.Job,''))	-- check if job is different
			  end
    
		  -- update 'last crew' in Employee Header
		  if exists(select 1 from inserted where Crew is not null)
			  begin
			  update dbo.bPREH
			  set Crew = i.Crew, AuditYN = 'N'    -- to avoid HQMA auditing
			  from dbo.bPREH r
			  Join inserted i on i.Co=r.PRCo and i.Employee = r.Employee
			  Join dbo.bPRCR c with (nolock) on i.Co = c.PRCo and i.Crew = c.Crew   -- must be an existing Crew
			  where i.BatchTransType <> 'D'   -- skip deletes
				  and (i.PostDate >= r.LastUpdated or r.LastUpdated is null) -- only if posting date is later
    			  and isnull(r.Crew,'') <> isnull(i.Crew,'')		-- add crew check
			  end

		  -- #127867 LastUpdated needs to be updated whether or not Job or Crew was actually updated
		  update dbo.bPREH
		  set LastUpdated = i.PostDate
		  from dbo.bPREH r with (nolock) 
		  join inserted i on i.Co = r.PRCo and i.Employee = r.Employee
		  where i.BatchTransType = 'A' and (i.PostDate > r.LastUpdated or r.LastUpdated is null)

		  -- issue 16023 fix for rejection - change bPREH AuditYN values back to 'Y' after updating last crew
		  update dbo.bPREH
		  set AuditYN = 'Y'
		  from dbo.bPREH r
		  join inserted i on i.Co = r.PRCo and i.Employee = r.Employee
		  where i.BatchTransType <> 'D' and r.LastUpdated = i.PostDate
 			  and isnull(r.AuditYN,'') <> 'Y'	-- check if AuditYN is not 'Y'

			end
		end
     
		-- Issue 131640 Add update to SM Work Completed records.
		-- Check to see if there are any SM records that need to create updates
	    IF NOT EXISTS(SELECT 1 FROM INSERTED I 
						INNER JOIN DELETED D ON I.KeyID=D.KeyID
						WHERE I.BatchTransType='A' AND (I.Type='S' OR D.Type='S'))
		BEGIN
			GOTO SM_Process_End
		END
		
		-- Update SMWorkCompleted with Changes.
		/* Create a matching record in SMWorkCompleted linked with records in SMBC */
		/* For each MyTimesheetDetail record one SMWorkCompleted record will be created for each day that is not null */
		DECLARE @WorkCompleted int, @PRCo bCompany, @BatchMth bMonth, @Employee int, @Amt bDollar,
				@PostDate smalldatetime, @BatchId bBatchID, @BatchSeq int, @SMCo bCompany, @SMWorkOrder int, @SMScope int, @OldSMScope int,
				@SMPayType varchar(10), @SMCostType smallint, @Technician varchar(15), @TaxRate bRate, @ServiceSite varchar(20), 
				@rcode int,@msg varchar(255), @Hours bHrs, @LinkRecordExists bit, @IsBilled bit, @UpdateInProgress bit,
				@SMWorkCompletedID bigint, @Type char(1), @OldType char(1), @OldSMCo bCompany, @OldSMWorkOrder int,
				@Craft bCraft, @Class bClass, @Shift tinyint, @OldCraft bCraft, @OldClass bClass, @OldShift tinyint,
				@OldHours bHrs, @OldPostDate smalldatetime, @OldSMPayType varchar(10), @OldSMCostType smallint,
				@SMJCCostType dbo.bJCCType, @PhaseGroup dbo.bGroup, @OldSMJCCostType dbo.bJCCType, @OldPhaseGroup dbo.bGroup
		
		/* Setup flag for possible error situations */
		DECLARE @bTechnicianInvalid bit
IF (@PrintDebug=1) PRINT 'btPRTBu 1'
		DECLARE cInserted CURSOR FOR
		SELECT I.Co, I.Mth, I.BatchId, I.BatchSeq, I.PostDate, I.Employee, I.Hours, I.Amt, I.SMCo, I.SMWorkOrder, I.SMScope, I.SMPayType, I.SMCostType, I.Type, 
		D.Type, D.SMCo, D.SMWorkOrder, D.SMScope, I.Craft, I.Class, I.Shift, D.Craft, D.Class, D.Shift, D.Hours, D.PostDate, D.Type, D.SMPayType, D.SMCostType,
		I.SMJCCostType, I.PhaseGroup, D.SMJCCostType, D.PhaseGroup
		FROM INSERTED I
		INNER JOIN DELETED D ON I.KeyID=D.KeyID
		WHERE I.BatchTransType='A' AND (I.Type='S' OR D.Type='S')
		
		OPEN cInserted
		FETCH NEXT FROM cInserted INTO @PRCo, @BatchMth, @BatchId, @BatchSeq, @PostDate, @Employee, @Hours, @Amt, @SMCo, 
			@SMWorkOrder, @SMScope, @SMPayType, @SMCostType, @Type, @OldType, @OldSMCo, @OldSMWorkOrder, @OldSMScope, @Craft, @Class, @Shift,
			@OldCraft, @OldClass, @OldShift, @OldHours, @OldPostDate, @OldType, @OldSMPayType, @OldSMCostType,
			@SMJCCostType, @PhaseGroup, @OldSMJCCostType, @OldPhaseGroup
		
		WHILE @@FETCH_STATUS = 0
				BEGIN
				/* Check to see if anyhting has changed that needs to be updated to SMWorkCompleted */
				IF (dbo.vfIsEqual(@SMCo,@OldSMCo)&dbo.vfIsEqual(@SMWorkOrder,@OldSMWorkOrder)&dbo.vfIsEqual(@SMPayType,@OldSMPayType)&dbo.vfIsEqual(@SMCostType,@OldSMCostType)&dbo.vfIsEqual(@Hours,@OldHours)&
					dbo.vfIsEqual(@Craft,@OldCraft)&dbo.vfIsEqual(@Class,@OldClass)&dbo.vfIsEqual(@Shift,@OldShift)&dbo.vfIsEqual(@PostDate,@OldPostDate)&
					dbo.vfIsEqual(@Type,@OldType)&dbo.vfIsEqual(@SMScope,@OldSMScope)&
					dbo.vfIsEqual(@SMJCCostType,@OldSMJCCostType)&dbo.vfIsEqual(@PhaseGroup,@OldPhaseGroup)=1)
				BEGIN
					GOTO NextSMRecord
				END
IF (@PrintDebug=1) PRINT 'btPRTBu 2'
				-- Check to see if this SMWorkCompleted record is already linked to a PRTB record.
				IF EXISTS(SELECT 1 FROM vSMBC WHERE PostingCo=@PRCo AND InUseMth=@BatchMth AND InUseBatchId=@BatchId
							AND InUseBatchSeq=@BatchSeq)
				BEGIN
					SET @LinkRecordExists = 1
					SELECT @UpdateInProgress=UpdateInProgress, @SMWorkCompletedID=SMWorkCompletedID FROM vSMBC WHERE PostingCo=@PRCo AND InUseMth=@BatchMth AND InUseBatchId=@BatchId
							AND InUseBatchSeq=@BatchSeq

					-- Check to see if the SMWorkCompleted record has been billed.
					IF EXISTS(SELECT 1 FROM SMWorkCompleted
							LEFT JOIN SMInvoice ON SMInvoice.SMCo=SMWorkCompleted.SMCo AND SMInvoice.SMInvoiceID=SMWorkCompleted.SMInvoiceID
							WHERE NOT SMInvoice.SMInvoiceID IS NULL AND SMWorkCompleted.SMWorkCompletedID=@SMWorkCompletedID)
						SET @IsBilled = 1
					ELSE
						SET @IsBilled = 0
				END
				ELSE 
				BEGIN
					SELECT @LinkRecordExists = 0, @SMWorkCompletedID = NULL, @UpdateInProgress=0, @IsBilled = 0
				END
				
				/* Get the Technician from the Employee number */
IF (@PrintDebug=1) PRINT 'btPRTBu 3'
				SELECT @Technician=Technician FROM vSMTechnician WHERE SMCo = @SMCo AND PRCo = @PRCo
				AND Employee = @Employee
				IF @@ROWCOUNT = 0
					BEGIN
						SET @bTechnicianInvalid = 1
					END
				
				-- Do not continue to update SMWorkCompleted if update is in progress.
IF (@PrintDebug=1) PRINT 'btPRTBu 4: UpdateInProgress='+Convert(varchar, @UpdateInProgress)
				IF (@UpdateInProgress=1)
				BEGIN
					GOTO NextSMRecord
				END
				
IF (@PrintDebug=1) PRINT 'btPRTBu 5: LinkRecordExists='+Convert(varchar,@LinkRecordExists)+' Hours='+Convert(varchar,@Hours)
				
				IF (@LinkRecordExists=1 AND (dbo.vfIsEqual(@SMCo,@OldSMCo)&dbo.vfIsEqual(@SMWorkOrder,@OldSMWorkOrder)&dbo.vfIsEqual(@SMScope,@OldSMScope)=0))
				BEGIN
					BEGIN TRY
						-- Set the UpdateInProgress flag on the SMBC link
						UPDATE vSMBC SET UpdateInProgress=1 
							WHERE PostingCo=@PRCo AND InUseMth=@BatchMth
							AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq
						
						-- Check to see if the SMWorkCompleted record has been billed.
						IF (@IsBilled = 1)
						BEGIN
							-- The SMWorkCompleted record has been billed so it cannot be deleted.  Just set the Cost values to zero.
IF (@PrintDebug=1) PRINT 'btPRTBu 6: Update SMWorkCompleted'
							UPDATE SMWorkCompleted SET CostQuantity=0, ProjCost=0
								WHERE SMWorkCompletedID IN
								(SELECT SMWorkCompletedID FROM vSMBC WHERE PostingCo=@PRCo AND InUseMth=@BatchMth 
									AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq)
						END
						ELSE
						BEGIN
							-- Delete the SMWorkCompleted record that is linked to the MyTimesheetDetail record.
IF (@PrintDebug=1) PRINT 'btPRTBu 7: Delete SMWorkCompleted'
							DELETE SMWorkCompleted WHERE SMWorkCompletedID IN 
								(SELECT SMWorkCompletedID FROM vSMBC WHERE PostingCo=@PRCo AND InUseMth=@BatchMth 
									AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq)
						END
						-- Delete the Link record
IF (@PrintDebug=1) PRINT 'btPRTBu 8: Delete vSMBC'
						DELETE vSMBC
							WHERE PostingCo=@PRCo AND InUseMth=@BatchMth 
							AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq
						-- Set the Link Exists flag to false.
						SELECT @LinkRecordExists=0, @SMWorkCompletedID=NULL
					END TRY
					BEGIN CATCH
						SET @errmsg = 'Error updating SMWorkCompleted when Invoiced = ' + CASE WHEN @IsBilled=1 THEN 'True' ELSE 'False' END
						GOTO error
					END CATCH
				END
				/* Check to see if a new WorkCompleted records needs to be created. */
				IF (@Type='S')
				BEGIN
					IF (@LinkRecordExists = 0)
					BEGIN
						SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @SMWorkOrder)

						/* Now create a linking record in SMBC for each new SMWorkCompleted record.
							The link must be created first so that the Insert of the SMWorkCompleted Labor record 
							doesn't create a PRMyTimesheetDetail record.
						*/
	IF (@PrintDebug=1) PRINT 'btPRTBu 9: Calling vspSM_PRTB_LinkCreate'
						exec @rcode = vspSM_PRTB_LinkCreate @SMCo=@SMCo, @WorkOrder=@SMWorkOrder, @Scope=@SMScope, 
							@PRCo=@PRCo, @BatchMth=@BatchMth, @BatchId=@BatchId, @BatchSeq=@BatchSeq,
							@WorkCompleted=@WorkCompleted, @errmsg=@errmsg OUTPUT
						
						IF (@rcode = 1)
						BEGIN
							SET @errmsg = 'Error creating SMBC.'
							GOTO error
						END
							
						-- Add a SMWorkCompleted record
	IF (@PrintDebug=1) PRINT 'btPRTBu 10: Calling vspSMWorkCompletedLaborCreate'
						exec @rcode = vspSMWorkCompletedLaborCreate @SMCo=@SMCo, @WorkOrder=@SMWorkOrder, @WorkCompleted = @WorkCompleted,
							@Scope=@SMScope, @PayType=@SMPayType, @SMCostType=@SMCostType, @Technician=@Technician, @Date=@PostDate, @Hours=@Hours, 
							@TCPRCo=@PRCo, @Craft=@Craft, @Class=@Class, @Shift=@Shift, @SMJCCostType=@SMJCCostType, @SMPhaseGroup=@PhaseGroup,
							@SMWorkCompletedID=@SMWorkCompletedID OUTPUT, @msg=@errmsg OUTPUT
							
						IF (@rcode = 1)
						BEGIN
							SET @errmsg = 'Error creating SMWorkCompletedLabor.'
							GOTO error
						END

						-- Update link with the SMWorkCompletedID
	IF (@PrintDebug=1) PRINT 'btPRTBu 11: Update vSMBC'
						UPDATE vSMBC SET SMWorkCompletedID=@SMWorkCompletedID
							WHERE PostingCo=@PRCo AND InUseMth=@BatchMth AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq
						
					END
					ELSE
					BEGIN
						-- Update SMWorkCompleted with the new information for SMCo, Workorder, Technician and hours.
						-- Check to see if the SMCo or WorkOrder is still the same.
	IF (@PrintDebug=1) PRINT 'btPRTBu 12: Checking vSMBC'
	IF (@PrintDebug=1) PRINT ' PRCo='+CONVERT(varchar, ISNULL(@PRCo,0))+' BatchMth='+CONVERT(varchar, @BatchMth,101)+' BatchId='+CONVERT(varchar, ISNULL(@BatchId,0))+' BatchSeq='+CONVERT(varchar, ISNULL(@BatchSeq,0))						
						IF EXISTS(SELECT 1 FROM vSMBC WHERE PostingCo=@PRCo AND InUseMth=@BatchMth AND InUseBatchId=@BatchId 
							AND InUseBatchSeq=@BatchSeq AND SMCo=@SMCo AND WorkOrder=@SMWorkOrder AND UpdateInProgress=0)
						BEGIN
							-- Set the UpdateInProgress flag on the SMBC link
							UPDATE vSMBC SET UpdateInProgress=1
								WHERE PostingCo=@PRCo AND InUseMth=@BatchMth
								AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq
	IF (@PrintDebug=1) PRINT 'btPRTBu 13: vspSMWorkCompletedLaborUpdate.'
	IF (@PrintDebug=1) PRINT ' WorkOrder='+CONVERT(varchar, @SMWorkOrder)+' Scope='+CONVERT(varchar, @SMScope)+' PayType='+@SMPayType+' Technician='+@Technician+' Date='+CONVERT(varchar, @PostDate,101)+' Hours='+CONVERT(varchar, @Hours)
							exec @rcode = vspSMWorkCompletedLaborUpdate @SMCo=@SMCo, @WorkOrder=@SMWorkOrder, @Scope=@SMScope, @PayType=@SMPayType, @SMCostType=@SMCostType,
								@Technician=@Technician, @Date=@PostDate, @Hours=@Hours, @SMWorkCompletedID=@SMWorkCompletedID, 
								@TCPRCo=@PRCo, @Craft=@Craft, @Class=@Class, @Shift=@Shift, @SMJCCostType=@SMJCCostType, @SMPhaseGroup=@PhaseGroup, @msg=@errmsg OUTPUT

							-- Set the UpdateInProgress flag on the SMBC link
							UPDATE vSMBC SET UpdateInProgress=0
								WHERE PostingCo=@PRCo AND InUseMth=@BatchMth
								AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq

							IF (@rcode = 1)
							BEGIN
								SET @errmsg = 'Error updating SMWorkCompletedLabor.'
								GOTO error
							END
						END
						ELSE
						BEGIN
							/* The SMCo or WorkOrder has changed so the current WorkCompelted record needs to be deleted and a
								new one created. */
							BEGIN TRY
								-- Set the UpdateInProgress flag on the SMBC link
								UPDATE vSMBC SET UpdateInProgress=1 
									WHERE PostingCo=@PRCo AND InUseMth=@BatchMth
									AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq
								
								-- Check to see if the SMWorkCompleted record has been billed.
								IF (@IsBilled = 1)
								BEGIN
									-- The SMWorkCompleted record has been billed so it cannot be deleted.  Just set the Cost values to zero.
	IF (@PrintDebug=1) PRINT 'btPRTBu 14: Update SMWorkCompleted'
									UPDATE SMWorkCompleted SET CostQuantity=0, ProjCost=0
										WHERE SMWorkCompletedID =@SMWorkCompletedID
								END
								ELSE
								BEGIN
									-- Delete the SMWorkCompleted record that is linked to the MyTimesheetDetail record.
	IF (@PrintDebug=1) PRINT 'btPRTBu 15: Delete SMWorkCompleted'
									DELETE SMWorkCompleted WHERE SMWorkCompletedID IN
										(SELECT SMWorkCompletedID FROM vSMBC WHERE PostingCo=@PRCo AND InUseMth=@BatchMth
											AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq)
								END
								
								-- Delete the Link record
	IF (@PrintDebug=1) PRINT 'btPRTBu 16: Update vSMBC'
								SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @SMWorkOrder)
								
								UPDATE vSMBC
									SET SMCo=@SMCo, WorkOrder=@SMWorkOrder, WorkCompleted=@WorkCompleted,
										SMWorkCompletedID=NULL, UpdateInProgress=1
									WHERE PostingCo=@PRCo AND InUseMth=@BatchMth
									AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq
								
								-- Add a SMWorkCompleted record
	IF (@PrintDebug=1) PRINT 'btPRTBu 17: Calling vspSMWorkCompletedLaborCreate'
								exec @rcode = vspSMWorkCompletedLaborCreate @SMCo=@SMCo, @WorkOrder=@SMWorkOrder, @WorkCompleted = @WorkCompleted,
									@Scope=@SMScope, @PayType=@SMPayType, @SMCostType=@SMCostType, @Technician=@Technician, @Date=@PostDate, @Hours=@Hours,
									@TCPRCo=@PRCo, @Craft=@Craft, @Class=@Class, @Shift=@Shift,
									@SMJCCostType=@SMJCCostType, @SMPhaseGroup=@PhaseGroup,
									@SMWorkCompletedID=@SMWorkCompletedID OUTPUT, @msg=@errmsg OUTPUT
									
								IF (@rcode = 1)
								BEGIN
									SET @errmsg = 'Error creating SMWorkCompletedLabor.'
									GOTO error
								END
							END TRY
							BEGIN CATCH
								SET @errmsg = 'Error updating SMWorkCompleted when Invoiced = ' + CASE WHEN @IsBilled=1 THEN 'True' ELSE 'False' END + ' ('+ERROR_MESSAGE()+')'
								GOTO error
							END CATCH
							
							-- Update link with the SMWorkCompletedID
	IF (@PrintDebug=1) PRINT 'btPRTBu 18: Update vSMBC'
							UPDATE vSMBC SET SMWorkCompletedID=@SMWorkCompletedID, UpdateInProgress=0
								WHERE PostingCo=@PRCo AND InUseMth=@BatchMth AND InUseBatchId=@BatchId AND InUseBatchSeq=@BatchSeq
						END
					END
				END
NextSMRecord:
				/* Get the next MyTimesheetDetail record */
				FETCH NEXT FROM cInserted INTO @PRCo, @BatchMth, @BatchId, @BatchSeq, @PostDate, @Employee, @Hours, @Amt, @SMCo,
					@SMWorkOrder, @SMScope, @SMPayType, @SMCostType, @Type, @OldType, @OldSMCo, @OldSMWorkOrder, @OldSMScope, @Craft, @Class, @Shift,
					@OldCraft, @OldClass, @OldShift, @OldHours, @OldPostDate, @OldType, @OldSMPayType, @OldSMCostType, 
					@SMJCCostType, @PhaseGroup, @OldSMJCCostType, @OldPhaseGroup
			END
			
		CLOSE cInserted
		DEALLOCATE cInserted
		
SM_Process_End:
      return
      
      error:
          select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Timecard Batch'
          RAISERROR(@errmsg, 11, -1);
          rollback transaction
GO
CREATE UNIQUE CLUSTERED INDEX [biPRTB] ON [dbo].[bPRTB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPRTBEmp] ON [dbo].[bPRTB] ([Employee]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPRTBJob] ON [dbo].[bPRTB] ([Job]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRTB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRTB].[DayNum]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRTB].[Cert]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRTB].[Rate]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRTB].[OldCert]'
GO
