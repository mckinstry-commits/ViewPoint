
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE       procedure [dbo].[bspEMBFRevBdownVal]
/***********************************************************
* CREATED BY: 	 bc 02/08/99
* MODIFIED By : bc 04/17/01  for issue 13107  Added addtional code for std rate and
*                             modified calcuation when rate is overridden
*               bc 05/03/01 - if EMRH.ORideFlag = 'N' then send the code-flow into EMRR_Catgy
*                             for the breakdowncode information
*	 JM 5-13-02 Ref Issue 17259 - @base_rate can be 0 causing a division by zero error;
*		see approx line 432.
*	 TV 02/11/04 - 23061 added isnulls
*	 TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
*				GF 01/18/2013 TK-20836 when creating old entries use EMBR for value to back out
*				GF 04/04/2013 TFS-46093 NS 42471 get old GLCo for old transactions if needed.
*
*
*	 
* USAGE:  Called to validate revenue breakdown code(s) for a piece of equipement
*	and processes any gl accounts accociated with the revenue breakdown code in the
*	department table into EMBC for inserting or updating EMGL back in EMBFUsageVal
*
* For a change to an existing transaction, the old values will come from EMRB for the breakdown
* codes. This will be the revenue code, breakdown code, amount, GL Company, and GL Account. All
* other information will derive based on the current EM setup.
*
*
* INPUT PARAMETERS
*	@co  		mbtkFormCo
*	@emgroup
*	@batchid
*	@seq
*	@mth
*	@dept 		department of the equipment doing the work
*	@revcode
* 	@equip		equipment doing the work
*	@catgy		of the equipment doing the work
* 	@jcco		job company that the equip is working for
*	@job		job the equipment is assigned to
*	@transtype	J, E, X or W
*	@revrate	rate input from the entry form
*	@oldnew		if the value = 1 then the entry is new and treated accordingly in the code
*			if the vaule = 0 then the entry is old and the input parameters should represent
*			the previous values posted as well as reverse the rates that are inserted into EMBC.
*	@post_to_gl	if 'Y' that means that there is not a revenue code set up in EMDR for this trans,
*			meaning the Revenue Breakdown code is going to drive the GL distribution.
*			if 'N' then Revenue Codes drive GL but we still come in here for
*			the rate amounts for posting to EMRB.
*
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong.  ie  @errorcount > 0
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@co bCompany, @emgroup bGroup, @batchid bBatchID, @seq int, @mth bMonth, @dept bDept, @revcode bRevCode,
 @equip bEquip, @catgy bCat, @jcco bCompany = null, @job bJob = null, @transtype char(1),
 @revrate bDollar, @oldnew tinyint, @post_to_gl bYN,
 ----TK-20836
 @OldRevTotal bDollar = 0,
 @emtrans bTrans = NULL,
 @errmsg varchar(255) OUTPUT)
as
set nocount on
   
declare @rcode int, @cnt int, @transacct bGLAcct, @revbdowncode varchar(10), @bdown_rate bDollar,
		@bdown_glco bCompany, @revtemp varchar(10), @base_rate bDollar, @running_total bDollar,
		@rate_diff bDollar, @errortext varchar(255), @errorstart varchar(50), @errorcount int,
		@typeflag char(1), @oriderate bYN
		----TK-20836
		,@OldRevBDownTotal bDollar
   
select @rcode = 0, @cnt = 0, @running_total = 0, @errorcount = 0

select @errorstart = 'Seq#' + isnull(convert(varchar(6),@seq),'')

----TFS-46093
DECLARE @oldglco bCompany
SELECT @oldglco = GLCo
FROM dbo.bEMCO
WHERE EMCo = @co
IF @@ROWCOUNT = 0 SET @oldglco = @co


---- TK-20836 IF PROBLEM OCCURS CREATEING OUT OLD BREAKDOWN CODE DISTRIBUTION
---- THIS SECTION CAN BE REMMED OUT. OF COURSE, THEN WE WILL USING NEW REVENUE
---- BREAKDOWN SETUP WHICH MAY RESULT IN INCORRECT ACCOUNTS AND AMOUNTS.
IF @oldnew = 0
	BEGIN
	---- reverse the old revenue total
	SET @OldRevTotal = -(@OldRevTotal)

	---- log error for missing EM Transaction
	IF @emtrans IS NULL
		BEGIN      
		SELECT @errmsg = ' - missing EM Transaction for Batch Sequence.'
		SELECT @errorcount = @errorcount + 1
		SELECT @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
       	EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		END

	---- insert old records from EMRB join EMDB for GLAccount if not in EMRB  
	INSERT INTO dbo.bEMBC(EMCo, Mth, BatchId, BatchSeq, OldNew, EMGroup, EMTrans, Equipment, RevBdownCode,
					RevCode, GLCo, Account, BdownRate)
	SELECT @co, @mth, @batchid, @seq, 0, @emgroup, @emtrans, EMRB.Equipment, EMRB.RevBdownCode,
					----TFS-46093
					EMRB.RevCode, ISNULL(EMRB.GLCo, @oldglco), ISNULL(EMRB.Account, EMDB.GLAcct), -(EMRB.Amount)
	FROM dbo.bEMRB EMRB WITH (NOLOCK)
	LEFT JOIN dbo.bEMDB EMDB WITH (NOLOCK) ON EMDB.EMCo=EMRB.EMCo AND EMDB.Department=@dept AND EMDB.EMGroup=EMRB.EMGroup AND EMDB.RevBdownCode=EMRB.RevBdownCode
	WHERE EMRB.EMCo = @co
		AND EMRB.Mth = @mth
		AND EMRB.Trans = @emtrans

		

	---- NEED TO VALIDATE THAT THE SUM OF OLD REVENUE BREAKDOWN CODES EQUAL THE OLD REVENUE VALUE
	---- IF NOT THEN THE FIRST BREAKDOWN SHOULD BE UPDATED WITH THE DIFFERENCE.
	---- SHOULD NEVER HAPPEN, BUT WE DO NOT WANT THE OLD DEBITS <> OLD CREDITS
	SET @OldRevBDownTotal = 0
	SELECT @OldRevBDownTotal = SUM(ISNULL(BdownRate,0))
	FROM dbo.bEMBC
	WHERE EMCo = @co
		AND Mth = @mth
		AND BatchId = @batchid
		AND BatchSeq = @seq
		AND OldNew = 0

	IF @OldRevBDownTotal IS NULL SET @OldRevBDownTotal = 0
	IF @OldRevTotal IS NULL SET @OldRevTotal = 0
	---- old revenue breakdown total <> old revenue total adjust first revenue breakdown code
	IF @OldRevBDownTotal <> @OldRevTotal
		BEGIN
		UPDATE t
			SET t.BdownRate = t.BdownRate + (@OldRevTotal - @OldRevBDownTotal)      
		FROM (SELECT TOP 1 *
			  FROM dbo.bEMBC
			  WHERE EMCo = @co
				AND Mth = @mth
				AND BatchId = @batchid
				AND BatchSeq = @seq
				AND OldNew = 0
			  ORDER BY RevBdownCode ASC) t
		END
 

	---- validate old GL Accounts 
	---- when flag is 'Y' then the revenue breakdown codes will drive the GL distributions
	IF @post_to_gl = 'Y'
		BEGIN
		---- spin through the revenue breakdown codes and validate GL Accounts
		SELECT @revbdowncode = MIN(RevBdownCode)
		FROM dbo.bEMBC
		WHERE EMCo = @co
			AND Mth = @mth
			AND BatchId = @batchid
			AND BatchSeq = @seq
			AND OldNew = 0

		WHILE @revbdowncode IS NOT NULL
			BEGIN
			---- get GL info
			SET @bdown_glco = NULL
			SET @transacct = NULL
			SELECT @bdown_glco = GLCo,
					@transacct = Account
			FROM dbo.bEMBC
			WHERE EMCo = @co
				AND Mth = @mth
				AND BatchId = @batchid
				AND BatchSeq = @seq
				AND OldNew = 0
				AND RevBdownCode = @revbdowncode

			---- log error for missing GL Account
			IF @transacct IS NULL
				BEGIN      
				SELECT @errmsg = ' - the Old Revenue Breakdown Code: ' + dbo.vfToString(@revbdowncode) +
   								 ' for Revenue Code: ' + dbo.vfToString(@revcode) +
								 ' is not set up in Department: ' + dbo.vfToString(@dept) +
   								 ' for Equipment: ' + dbo.vfToString(@equip)
				SELECT @errorcount = @errorcount + 1
				SELECT @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
       			EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				END
            ELSE
				BEGIN
				---- validate old GL Account              
				EXEC @rcode = bspGLACfPostable @bdown_glco, @transacct, 'E', @errmsg output
				if @rcode <> 0
					BEGIN
					SELECT @errorcount = @errorcount + 1
					SELECT @errortext = dbo.vfToString(@errorstart) +
								' - the Old Revenue Breakdown Code: ' + dbo.vfToString(@revbdowncode) + 
								': GL Account: ' + dbo.vfToString(@transacct) +
								': ' + dbo.vfToString(@errmsg)
					EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					IF @rcode <> 0 goto bspexit
					END
				END                  

			---- next revenue breakdown code
			SELECT @revbdowncode = MIN(RevBdownCode)
			FROM dbo.bEMBC
			WHERE EMCo = @co
				AND Mth = @mth
				AND BatchId = @batchid
				AND BatchSeq = @seq
				AND OldNew = 0
				AND RevBdownCode > @revbdowncode
			END

		END ---- end IF @post_to_gl = 'Y'

	END	---- end IF @oldnew = 0

---- done with old entries
IF @oldnew = 0 GOTO bspexit



SET @revbdowncode = NULL
SET @bdown_glco = NULL
SET @transacct = NULL

/* Get the base value of the revenue rate from EMRR */
select @base_rate = min(Rate)
from bEMRR
where EMCo = @co and EMGroup = @emgroup and isnull(Category,'') = isnull(@catgy,'') and RevCode = @revcode

/* get the offset acct(s) for EMGL based on the department revenue bdown code(s) */
if @transtype = 'J'
    BEGIN
   
     /* Check to see if there is a template set up for this job */
     select @revtemp = RevTemplate
     from bEMJT
     where EMCo = @co and JCCo = @jcco and Job = @job
   
     if @revtemp is not null
     /* check to see if the RevCode passed in is used in this template */
       BEGIN
   
       select @typeflag = TypeFlag
       from bEMTH
       where EMCo = @co and RevTemplate = @revtemp
   
       select @cnt = count(*)
       from bEMTE
       where EMCo = @co and RevTemplate = @revtemp and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode
   
       if @cnt = 1
       /* the RevCode is setup in this template */
         Begin
   
         if @typeflag = 'O'
           begin
           select @base_rate = Rate
           from bEMTE
           where EMCo = @co and RevTemplate = @revtemp and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode
           end
   
   
         /* spin through the rev bdown codes for this Equip/RevCode/Template.
            if they are all valid in the department table then insert information into EMBC */
         select @revbdowncode = min(RevBdownCode)
         from bEMTF
         where EMCo = @co and EMGroup = @emgroup and RevTemplate = @revtemp and Equipment = @equip and
          	    RevCode = @revcode
   
         while @revbdowncode is not null
           Begin --3
           select @bdown_glco = null, @transacct = null
           select @bdown_glco = GLCo, @transacct = GLAcct
           from bEMDB
           where EMCo = @co and isnull(Department,'') = isnull(@dept,'') and EMGroup = @emgroup and RevBdownCode = @revbdowncode
   
           if @post_to_gl = 'Y'
             begin
             if @transacct is null
               begin
               select @errmsg = ' - In the equipment job template ' + isnull(@revtemp,'') + ', the RevBdownCode ' + isnull(@revbdowncode,'') +
   			   ' for revenue code ' + isnull(@revcode,'') + ' is not set up in department ' + isnull(@dept,'') +
   			   ' for equipment ' + isnull(@equip,'')
   	        select @errorcount = @errorcount + 1
               select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
       	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
   
               goto loop1
   	        end
   
             exec @rcode = bspGLACfPostable @bdown_glco, @transacct, 'E', @errmsg output
             if @rcode <> 0
               begin
               select @errorcount = @errorcount + 1
               select @errortext = isnull(@errorstart,'') + '- GLAcct:' + isnull(@transacct,'') + ':  ' + isnull(@errmsg,'')
               exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
               if @rcode <> 0 goto bspexit
       	    goto loop1
       	    end
             end
   
           select @bdown_rate = Rate
           from bEMTF
           where EMCo = @co and EMGroup = @emgroup and RevTemplate = @revtemp and Equipment = @equip and
                 RevCode = @revcode and RevBdownCode = @revbdowncode
   
           insert into bEMBC(EMCo, Mth, BatchId, BatchSeq, OldNew, EMGroup, Equipment, RevBdownCode, RevCode,
                             GLCo, Account, BdownRate)
           values(@co, @mth, @batchid, @seq, @oldnew, @emgroup, @equip, @revbdowncode, @revcode,
					----TFS-46093
                  ISNULL(@bdown_glco, @oldglco), @transacct, case @oldnew when 1 then @bdown_rate else -(@bdown_rate) end)
   
           loop1:
           select @revbdowncode = min(RevBdownCode)
           from bEMTF
           where EMCo = @co and EMGroup = @emgroup and RevTemplate = @revtemp and Equipment = @equip and
                 RevCode = @revcode and RevBdownCode > @revbdowncode
           end
         End
   
       /* check category template for revenue breakdown codes */
       Else
         Begin
   
         select @cnt = count(*)
         from bEMTC
         where EMCo = @co and RevTemplate = @revtemp and isnull(Category,'') = isnull(@catgy,'') and EMGroup = @emgroup and RevCode = @revcode
   
         if @cnt = 1
           /* the RevCode is set up for this template */
           begin
   
           if @typeflag = 'O'
             begin
             select @base_rate = Rate
             from bEMTC
             where EMCo = @co and RevTemplate = @revtemp and isnull(Category,'') = isnull(@catgy,'') and EMGroup = @emgroup and RevCode = @revcode
             end
   
           /* spin through the rev bdown codes for this Catgy/RevCode/Template.
              if they are all valid in the department table then insert information into EMBC */
           select @revbdowncode = min(RevBdownCode)
           from bEMTD
           where EMCo = @co and EMGroup = @emgroup and RevTemplate = @revtemp and isnull(Category,'') = isnull(@catgy,'') and
           	    RevCode = @revcode
   
           while @revbdowncode is not null
             begin
             select @bdown_glco = null, @transacct = null
             select @bdown_glco = GLCo, @transacct = GLAcct
             from bEMDB
             where EMCo = @co and isnull(Department,'') = isnull(@dept,'') and EMGroup = @emgroup and RevBdownCode = @revbdowncode
   
             if @post_to_gl = 'Y'
               begin
               if @transacct is null
                 begin
                 select @errmsg = ' - In the category job template ' + isnull(@revtemp,'') + ', the RevBdownCode ' + isnull(@revbdowncode,'') +
    			     ' for revenue code ' + isnull(@revcode,'') + ' is not set up in department ' + isnull(@dept,'') +
   			     ' for equipment ' + isnull(@equip,'')
   
                 select @errorcount = @errorcount + 1
                 select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
       	      exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                 if @rcode <> 0 goto bspexit
    	          goto loop2
                 end
   
               exec @rcode = bspGLACfPostable @bdown_glco, @transacct, 'E', @errmsg output
     	        if @rcode <> 0
       	      begin
       	      select @errorcount = @errorcount + 1
       	      select @errortext = isnull(@errorstart,'') + '- GLAcct:' + isnull(@transacct,'') + ':  ' + isnull(@errmsg,'')
     	          exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       	      if @rcode <> 0 goto bspexit
   
                 goto loop2
       	      end
               end
   
             select @bdown_rate = Rate
   	      from bEMTD
             where EMCo = @co and EMGroup = @emgroup and RevTemplate = @revtemp and isnull(Category,'') = isnull(@catgy,'') and
   	        RevCode = @revcode and RevBdownCode = @revbdowncode
   
             insert into bEMBC(EMCo, Mth, BatchId, BatchSeq, OldNew, EMGroup, Equipment, RevBdownCode, RevCode,
                			    GLCo, Account, BdownRate)
             values(@co, @mth, @batchid, @seq, @oldnew, @emgroup, @equip, @revbdowncode, @revcode,
                    @bdown_glco, @transacct, case @oldnew when 1 then @bdown_rate else -(@bdown_rate) end)
   
             loop2:
   	      select @revbdowncode = min(RevBdownCode)
   	      from bEMTD
             where EMCo = @co and EMGroup = @emgroup and RevTemplate = @revtemp and isnull(Category,'') = isnull(@catgy,'') and
   	            RevCode = @revcode and RevBdownCode > @revbdowncode
   	      end
           end
         End
       END --RevTemplate Not Null
     END -- TransType = 'J'
   
   
   
   /* validate revenue breakdown codes for a revenue code that was not included in a job template */
   select @cnt = count(*)
   from bEMBC
   where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and OldNew = @oldnew
   
   if @cnt = 0
   BEGIN
     select @cnt = count(*)
     from bEMRH
     where EMCo = @co and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
     if @cnt = 1
       /* the RevCode is setup for this piece of equipment */
       Begin
   
       select @oriderate = ORideRate
       from bEMRH
       where EMCo = @co and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
   
       /* go get rate and revenue breakdown info from the category set up
          if the EMEH.ORideRate = N */
       if @oriderate = 'N' goto EMRR_Catgy
   
       select @base_rate = Rate
       from bEMRH
       where EMCo = @co and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
   
   
       /* spin through the rev bdown codes for this Equip/RevCode.
          if they are all valid in the department table then insert information into EMBC */
       select @revbdowncode = min(RevBdownCode)
       from bEMBE
       where EMCo = @co and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
   
       while @revbdowncode is not null
         begin
         select @bdown_glco = null, @transacct = null
         select @bdown_glco = GLCo, @transacct = GLAcct
         from bEMDB
         where EMCo = @co and isnull(Department,'') = isnull(@dept,'') and EMGroup = @emgroup and RevBdownCode = @revbdowncode
   
         if @post_to_gl = 'Y'
           begin
           if @transacct is null
             begin
             select @errmsg = ' - RevBdownCode ' + isnull(@revbdowncode,'') +
   			   ' for revenue code ' + isnull(@revcode,'') + ' is not set up in department ' + isnull(@dept,'') +
   			   ' for equipment ' + isnull(@equip,'')
   
   	      select @errorcount = @errorcount + 1
       	  select @errortext = isnull(@errorstart,'') + ' ' + isnull(@errmsg,'')
       	  exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       	  if @rcode <> 0 goto bspexit
   
    	      goto loop3
   	      end
   
   	    exec @rcode = bspGLACfPostable @bdown_glco, @transacct, 'E', @errmsg output
     	    if @rcode <> 0
       	  begin
       	  select @errorcount = @errorcount + 1
       	  select @errortext = isnull(@errorstart,'') + '- GLAcct:' + isnull(@transacct,'') + ':  ' + isnull(@errmsg,'')
       	  exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       	  if @rcode <> 0 goto bspexit
       	  goto loop3
       	  end
           end
   
         select @bdown_rate = Rate
         from bEMBE
        where EMCo = @co and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode and RevBdownCode = @revbdowncode
   
         insert into bEMBC(EMCo, Mth, BatchId, BatchSeq, OldNew, EMGroup, Equipment, RevBdownCode, RevCode,
         			      GLCo, Account, BdownRate)
         values(@co, @mth, @batchid, @seq, @oldnew, @emgroup, @equip, @revbdowncode, @revcode,
				----TFS-46093
         	     ISNULL(@bdown_glco, @oldglco), @transacct, case @oldnew when 1 then @bdown_rate else -(@bdown_rate) end)
   
         loop3:
         select @revbdowncode = min(RevBdownCode)
         from bEMBE
     where EMCo = @co and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode and RevBdownCode > @revbdowncode
         end
       End
   
     Else
       /* look on the category side */
       Begin
   
       /**********/
       EMRR_Catgy:
       /**********/
   
       select @cnt = count(*)
       from bEMRR
       where EMCo = @co and EMGroup = @emgroup and isnull(Category,'') = isnull(@catgy,'') and RevCode = @revcode
       if @cnt = 1
         begin
   
         /* spin through the rev bdown codes for this Catgy/RevCode.
            if they are all valid in the department table then insert information into EMBC */
         select @revbdowncode = min(RevBdownCode)
         from bEMBG
         where EMCo = @co and EMGroup = @emgroup and isnull(Category,'') = isnull(@catgy,'') and RevCode = @revcode
   
         while @revbdowncode is not null
   	    begin
   	    select @bdown_glco = null, @transacct = null
   	    select @bdown_glco = GLCo, @transacct = GLAcct
   	    from bEMDB
   	    where EMCo = @co and isnull(Department,'') = isnull(@dept,'') and EMGroup = @emgroup and RevBdownCode = @revbdowncode
   
   	    if @post_to_gl = 'Y'
   	    begin
   	      if @transacct is null
   	        begin
   	     select @errmsg = ' - RevBdownCode ' + isnull(@revbdowncode,'') +
   			     ' for revenue code ' + isnull(@revcode,'') + ' is not set up in department ' + isnull(@dept,'') +
   			     ' for equipment ' + isnull(@equip,'')
   
   	        select @errorcount = @errorcount + 1
       	    select @errortext = @errorstart + ' ' + @errmsg
       	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       	    if @rcode <> 0 goto bspexit
   
    	        goto loop4
   	        end
   
   	     exec @rcode = bspGLACfPostable @bdown_glco, @transacct, 'E', @errmsg output
     	     if @rcode <> 0
       	       begin
       	       select @errorcount = @errorcount + 1
       	       select @errortext = isnull(@errorstart,'') + '- GLAcct:' + isnull(@transacct,'') + ':  ' + isnull(@errmsg,'')
       	       exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       	       if @rcode <> 0 goto bspexit
       	       goto loop4
       	       end
   	    end
   
   	   select @bdown_rate = Rate
   	   from bEMBG
   	   where EMCo = @co and EMGroup = @emgroup and isnull(Category,'') = isnull(@catgy,'') and RevCode = @revcode and RevBdownCode = @revbdowncode
   
         	   insert into bEMBC(EMCo, Mth, BatchId, BatchSeq, OldNew, EMGroup, Equipment, RevBdownCode, RevCode,
         	  			   GLCo, Account, BdownRate)
              values(@co, @mth, @batchid, @seq, @oldnew, @emgroup, @equip, @revbdowncode, @revcode,
             	  @bdown_glco, @transacct, case @oldnew when 1 then @bdown_rate else -(@bdown_rate) end)
   
   	   loop4:
   	   select @revbdowncode = min(RevBdownCode)
   
   	   from bEMBG
   	   where EMCo = @co and EMGroup = @emgroup and isnull(Category,'') = isnull(@catgy,'') and RevCode = @revcode and RevBdownCode > @revbdowncode
   	   end
   	end
   	else
   
   	/* the revenue side is not set up for this piece of equipment */
   	  begin
         select @errorcount = @errorcount + 1
   	  select @errmsg = 'There are no revenue breakdown code rates set up by equipment or category for equipment ' + isnull(@equip,'')
   	  select @errortext = isnull(@errorstart,'') + ' - ' + isnull(@errmsg,'')
         exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
         if @rcode <> 0 goto bspexit
   	  goto bspexit
   	  end
     end
   END
   
   /* calculate breakdown rates for an override (or underride) of EMRR standard rate.
      if, for some reason, there is a remainder amount after all the revbdowncodes have been processed
      then update the last revbdown code account with whatever is left */
   
   if @revrate <> @base_rate
     Begin
   
     select @revbdowncode = min(RevBdownCode)
     from bEMBC
     where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and OldNew = @oldnew
   
     while @revbdowncode is not null
       /* loop through the rates in EMBC and + or - them in proportion to how much over or under the
          revrate is compared to the standard rate in EMRR */
       begin
       select @bdown_rate = BdownRate
       from bEMBC
       where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and
       	  RevBdownCode = @revbdowncode and OldNew = @oldnew
   
       /* magical calculation for percentage of posting overrides */
       -- JM 5-13-02 Ref Issue 17259 - @base_rate can be 0 causing a division by zero error
       if @base_rate = 0
   	select @bdown_rate = 0
       else
   	select @bdown_rate = (@bdown_rate/@base_rate) * @revrate
   
   
       select @running_total = @running_total + @bdown_rate
   
       Update bEMBC
       Set BdownRate = @bdown_rate
       where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and
       	  RevBdownCode = @revbdowncode and OldNew = @oldnew
   
       select @revbdowncode = min(RevBdownCode)
       from bEMBC
       where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and
       	  OldNew = @oldnew and RevBdownCode > @revbdowncode
   
       end
   
     /* throw any remainder into last bdown code */
     select @revrate = case @oldnew when 1 then @revrate else -(@revrate) end
     if @running_total <> @revrate
       begin
       select @rate_diff = @revrate - @running_total
       select @revbdowncode = max(RevBdownCode)
       from bEMBC
       where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and OldNew = @oldnew

   
       update bEMBC
       set BdownRate = BdownRate + @rate_diff
       where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and
       	  RevBdownCode = @revbdowncode and OldNew = @oldnew
       end
     End
   
   bspexit:
   
   	if @errorcount > 0 select @rcode = 1
   	if @rcode<>0 select @errmsg=isnull(@errmsg,'')
   	return @rcode


GO

GRANT EXECUTE ON  [dbo].[bspEMBFRevBdownVal] TO [public]
GO
