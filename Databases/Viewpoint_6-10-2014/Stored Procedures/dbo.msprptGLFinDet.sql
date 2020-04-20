SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[msprptGLFinDet]
(
	@GLCo bCompany = null
,	@BegAcct bGLAcct='          '
,	@EndAcct bGLAcct='zzzzzzzzzz'
,	@BegMonth bMonth ='01/01/1950'
,	@EndMonth bMonth = '12/01/2050'
,	@IncludeInactive char(1)='N'
,	@Source varchar(20)=' '
,	@Journal varchar(20)=' '
,	@DetailLevel char(1) = 'D'
)
/*created 8/26/97 */
/*changed report to use GLAC instead of GLAC for security*/
/*mod JRE 3/27/02 Timing out for large GLs.  Re-wrote the get beginning balance to be more effecient
by eliminating an update by using a derived table in the insert, and reducing the size of #GLDetail*/
/*changed TRL 4/3/2002 Took out the IF BEGIN END statements used for selecting by detail level.  Added Union
statements and RecType field */
/*mod JRE 4/23/03  issue 21042 change  GLCO .. NOT NULL to GLCO .. NULL */
/* Issue 23660 Remove the #GLDetail table for Beg Balance and add Union statement with RecType='B' 03/04/04 NF */
/* Issue 26210 Moved the select statement into a secondary procedure for performance reasons */
/* Issue 26959 Places additional inputs into the stored procedure for efficiency 03/17/04 NF */
/* Issue 29223 Add @IncludeInactive to Where clause 7/6/5 NF*/
/* */
AS

set nocount ON

declare @FYEMO bMonth, @FYBMO bMonth, @EndAcctFull bGLAcct,@ErrorMessage varchar(60)
select @EndAcctFull=RTrim(@EndAcct)+'zzzzzzzzzz'


		/* if no begin month then get it from the end month */
		if @BegMonth is null
		begin
			select @BegMonth = GLFY.BeginMth
			from GLFY  
			where GLFY.GLCo=@GLCo and @EndMonth>=GLFY.BeginMth and @EndMonth<=GLFY.FYEMO
			if @@rowcount=0
			begin
				select @ErrorMessage= '**** Fiscal Year End not set up in GLFY ****'
			end
			goto selectresults
		end

		/* get Fiscal Year Begin Month */
		select @FYBMO = GLFY.BeginMth, @FYEMO=GLFY.FYEMO
		from GLFY 
		where GLFY.GLCo=@GLCo and @BegMonth>=GLFY.BeginMth and @BegMonth<=GLFY.FYEMO
		if @@rowcount=0
		begin
			select @ErrorMessage= '**** Fiscal Year End Beginning Month not set up****'
			goto selectresults
		end

		/* check if ending month is in same year as begin month */
		if @EndMonth <@BegMonth or @FYBMO is null
		begin
			select @ErrorMessage= '**** End month may not be less than the begin month ****'
			goto selectresults
		end
		if @EndMonth > @FYEMO or @FYEMO is null
		begin
			select @ErrorMessage= '**** End month is not in the same fiscal year as begin month ****'
			goto selectresults
		end


		--******************************************************************************************************
		--* select the results
		--******************************************************************************************************

		selectresults:
		PRINT CAST(@GLCo AS CHAR(10)) + @ErrorMessage
		
		SELECT 
			GLCo					--tinyint		NOT NULL	
		--,	GLAcct					--CHAR(20)	NOT NULL		
		--,	AcctType				--CHAR(1)		NULL
		--,	SubType					--CHAR(1)		NULL
		--,	NormBal					--CHAR(1)		NULL
		--,	InterfaceDetail			--bYN			NULL
		--,	ACTIVE					--bYN			NULL
		--,	SummaryAcct				--bGLAcct		NULL
		--,	CashAccrual				--CHAR(1)		NULL
		--,	CashOffAcct				--bGLAcct		NULL
		,	Part1					--varchar(20)	null
		--,	Description				--bDesc		NULL
		--,	Part2					--varchar(20)	null
		,	Part3					--varchar(20)	null
		--,	Part4					--varchar(20)	null
		--,	Part5					--varchar(20)	null
		--,	Part6					--varchar(20)	null
		--,	SummaryDesc				--varchar(30) null
		--,	SummaryActType			--CHAR(1)		NULL
		--,	SummarySubType			--CHAR(1)		NULL
		--,	SummaryActive			--bYN			NULL
		--,	SummaryNormBal			--bYN			NULL
		--,	BeginBal				--bDollar		null
		--,	GLTrans					--bTrans		null
		--,	Jrnl					--bJrnl		null
		--,	GLRef					--bGLRef		null
		--,	SourceCo				--bCompany	null
		--,	Source					--bSource		null
		--,	ActDate					--bDate		null
		--,	DetailDesc				--bTransDesc	null
		--,	BatchId					--bBatchID	null
		--,	Debit					--bDollar		null
		--,	Credit					--bDollar		null
		--,	Adjust					--CHAR(1)		null
		--,	Part2I					--char(20)	null
		--,	Part2IDesc				--bDesc		null
		--,	Part3I					--char(20)	null
		--,	Part3IDesc				--bDesc		null
		,	NetAmt					--bDollar		null
		,	Mth						--bMonth		NULL		
		--,	P1Desc					--varchar(30)	null
		--,	P2Desc					--varchar(30)	null
		--,	P3Desc					--varchar(30)	null
		--,	P4Desc					--varchar(30)	null
		--,	P5Desc					--varchar(30)	null
		--,	P6Desc					--varchar(30)	null
		--,	CoName					--varchar(60)	null
		--,	BegAcct					--bGLAcct		null
		--,	EndAcct					--bGLAcct		null
		--,	BegMonth				--bMonth		NULL
		--,	EndMonth				--bMonth		NULL
		--,	ErrorMessage			--varchar(60)	null
		--,	DetailLevel				--CHAR(1)		NULL
		--,	RecType					--CHAR(1)		NULL		
		FROM dbo.mfnrptGLFinDetSelect(@GLCo , @BegAcct , @EndAcct , @BegMonth, 
		@EndMonth ,@IncludeInactive, @Source, @Journal, @DetailLevel,
		@FYEMO, @FYBMO, @EndAcctFull, @ErrorMessage)		
		
	
GO
