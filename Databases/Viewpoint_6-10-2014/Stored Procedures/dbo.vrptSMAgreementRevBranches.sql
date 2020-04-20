SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Procedure [dbo].[vrptSMAgreementRevBranches] 
	(    
		  @SMCo bCompany     
		, @Customer bCustomer    
		, @Agreement VARCHAR(15)
		, @AgreementType VARCHAR(15)
	)
	
AS

/*==================================================================================      

Author:   
Adam Rink
Scott Alvey

Create date:   
08/10/12    

Usage:
Determines what term a revision of an agreement falls into. Used in the SM Agreements List report.

Things to keep in mind regarding this report and proc: 
A term is not something that is really defined in the database. Instead a term is a grouping
of related Agreement revisions. If I have:
Agr	Rev	PrevRev RevType
1	1	null	1
1	2	1		2
1	3	2		3
1	4	2		2
1	5	3		2

the groupings would be that Revs 1, 2, and 4 are in one term while Revs 3 and 5 are in another.
Here is the verbal chronilogical oder of that statement:

Rev 1: I create Rev 1 (PrevRev is null and RevType = 1 - Original) I am part of the first term
Rev 2: I ammend Rev 1 (PrevRev not null and RevType = 2 - Ammendment) I am part of the first term
Rev 3: I renew Rev 2 (PrevRev not null and RevType = 3 - Renewal) I am part of the second term
Rev 4: I ammend Rev 2 (PrevRev not null and RevType = 2 - Ammendment) I am part of the first term
Rev 5: I ammend Rev 3 (PrevRev not null and RevType = 2 - Ammendment) I am part of the second term	

so while 'term' is not something that is tracked in the software it is something that is 
understood by the user based on how the data was entered. Which makes this a PIA to track....

The code below determines what revision is part of what term for what agreement. First we go
through the agreement revisions and any line that has a Revision Type of 1 or 3 (original or
renewal) we put that line's Revision number in a new Branch column to signify that this line is the
start of a new term (branch makes a bit more sense in the code, for the purpose of documentation
branch and term are the same concept). So now we have a list of records that are either the start
of a brach (Branch is not null) or part of the branch (is null).

We take this data and dump it into a temp table so that we can update the Branch field for the 
null Branch lines. The next step is to loop through the lines and update the null Branch values
but first we need to know when to stop. So we get the max Revsion value of all the data and make
that our stopping point. This is not the max per agreement, but the max as a whole, and that is
fine. Now we loop through the records and any null branch values equal to the branch value of the
related PreviousRevision value. To use the same example data as you saw above, I will add a 
Brach column and demonstrate this

Agr	Rev	PrevRev RevType	Branch
1	1	null	1		1
1	2	1		2		null
1	3	2		3		3
1	4	2		2		null
1	5	3		2		null

now when I loop through I first ignore Rev 1 as the Branch value is not null
next in the loop is Rev 2. I see that it's Branch value is null so I look at its PreviousRevision
value and see that it is 1. I then look up the Branch value for Revision 1 and set that value
to Revision 2's Branch value. I then skip over Revision 3 (non null Branch value) and come to 
Revision 4. I see that its PreviousRevision value is Revision 2 so I lookup Revision's 2 Branch value 
and set that value to Revision 4's Branch value (1). Finall Revision 5 has a PreviousRevision value
of 3 and Revisions 3's Branch value is 3 so I set that as well. The end result is:

Agr	Rev	PrevRev RevType	Branch
1	1	null	1		1
1	2	1		2		1
1	3	2		3		3
1	4	2		2		1
1	5	3		2		3

Now I know my branches\terms.

Related reports:   
SM Agreement List (ID: 1225)    

Revision History      
Date		Author			Issue						Description

==================================================================================*/  

with

/*=================================================================================                      
CTE:
CTE_InvoicesWithInvoicedDates
                     
Usage: 
This CTE is used in the final select to link in agreement billed amounts
          
Things to keep in mind regarding this report and proc:
NA

Views:
SMAgreementBillingScheduleExt as smabse
	to be able to link the agreement services and related details to an invoice in
	the final call
SMInvoiceSession as smis
	to give us the InvoiceDate values
==================================================================================*/ 

CTE_InvoicesWithInvoicedDates

as

(
	SELECT
		smabse.SMCo
		, smabse.Agreement
		, smabse.Revision
		, smabse.Service
		, smabse.BillingAmount
		, smabse.TaxAmount
		, smabse.BillingType
		, smabse.SMInvoiceID
	FROM
		SMAgreementBillingScheduleExt smabse
)

SELECT
	Row_Number() Over( Order By
						smage.SMCo 
						, smage.Agreement 
						, smage.Revision
					 ) as RowNum
	, h.Name AS CompanyName 
	, smage.SMCo
	, smage.Agreement
	, smage.AgreementType
	, smage.AgreementStatus
	, smage.Description AS AgreementDescription
	, smage.Revision
	, smage.PreviousRevision
	, smage.RevisionType
	, CASE WHEN smage.RevisionType IN (1,3) 
		THEN smage.Revision 
		ELSE NULL 
	  END AS RevisionBranch
	, smage.CurrentActiveRevision
	, smage.RevisionStatus
	, smage.EffectiveDate
	, smage.DateActivated
	, smage.DateCancelled
	, smage.DateTerminated
	, smage.ExpirationDate
	, smage.AgreementPrice
	, AgreementBilled.AgreementBilledAmount	
	, a.CustGroup
	, a.Customer
	, a.Name AS CustomerName
	, a.Contact AS CustomerContactName
	, a.Phone AS CustomerContactPhone
INTO
	#AgreementRevisionBranches
FROM   
	SMAgreementExtended smage 
INNER JOIN 
	SMCustomer smc ON 
		smage.CustGroup=smc.CustGroup 
		AND smage.Customer=smc.Customer 
		AND smage.SMCo=smc.SMCo 
INNER JOIN 
	HQCO h ON 
		smage.SMCo=h.HQCo 
INNER JOIN 
	ARCM a ON 
		smc.CustGroup=a.CustGroup 
		AND smc.Customer=a.Customer
OUTER APPLY
	(
		SELECT
			isnull(SUM(c.BillingAmount),0) 
			+ isnull(SUM(c.TaxAmount),0) AS AgreementBilledAmount
		From 
			CTE_InvoicesWithInvoicedDates c  
		WHERE
			c.SMCo = smage.SMCo
			AND c.Agreement = smage.Agreement
			AND c.Revision = smage.Revision
			AND c.SMInvoiceID is not null			
	) AgreementBilled
WHERE  
	smage.SMCo = @SMCo
	AND (CASE WHEN @Customer = 0 THEN @Customer ELSE smage.Customer END) = @Customer
	AND (CASE WHEN @Agreement = '' THEN @Agreement ELSE smage.Agreement END) = @Agreement
	AND (CASE WHEN @AgreementType = '' THEN @AgreementType ELSE smage.AgreementType END) = @AgreementType	
ORDER BY 
	smage.SMCo
	, smage.Agreement
	, smage.Revision
	

/*
	uncomment select code below if would like the see the temp table results in SQL Studio
	do not run the report with this turned on as it will likely just piss off the report	
*/
	--select * FROM #AgreementRevisionBranches

--settting a loop counter (@cnt) and a loop limit (@maxRevision) so we know when to stop looping */

DECLARE @maxRevision BIGINT,
		@cnt BIGINT;
	
SET @cnt = 1;
SELECT @maxRevision = MAX(Revision) From #AgreementRevisionBranches

/*=======================================================================
loop through the temp table and every time we encounter a line that is not the start 
of a branching line (RevisionBranch is null) then figure out what branch the line is
a part of. 
========================================================================*/
	
WHILE @cnt <= @maxRevision 
BEGIN 

	UPDATE 
		Rev
	SET 
		RevisionBranch = Branch.RevisionBranch
	FROM 
		#AgreementRevisionBranches Branch
	JOIN 
		#AgreementRevisionBranches Rev ON 
			Rev.SMCo = Branch.SMCo 
			AND Rev.Agreement = Branch.Agreement 
			AND Rev.PreviousRevision = Branch.Revision	
	WHERE 
		Rev.Revision = @cnt
		AND Rev.RevisionBranch IS NULL
	SET @cnt = @cnt +1;
	
END;

/*=======================================================================
Because the report has the potential of filtering down to a single Revision in a 
single agreement we cannot rely on the report to give us some branch related 
summar information (like billings, and key dates). So the joining of 
#AgreementRevisionBranches to #AgreementRevisionBranches (via the CTE) 
is used to get those key dates because at this point the report has not done 
any filtering yet.

the max dates gives us, for a given branch, when the branch came effective,
was terminated, and such so that even if the report filters on a single
revision in that branch, the report can still the branch as a whole. While the
CTE gets us some of the dates it also gives us the last revison in the branch.
Joining the last revision back to AgreementRevisionBranches again will give us
the last dates of the branch, expiration or termination depending on the
status of the last revision

Agreement price and billings (in the CTE) are done at the branch level, and the min/max
status and revision values are used in the report to determine the status
of the branch (active, terminated, etc...)
========================================================================*/

with

CTE_Branches

as 

(
	select
		SMCo
		, Agreement
		, RevisionBranch
		, min(EffectiveDate) as BranchEffectiveDate
		, max(DateCancelled) as BranchCancelledDate
		, sum (
				case 
/*AmendmentQuote*/	when (RevisionStatus = 0 and PreviousRevision is not null and RevisionType = 2) then 0
/*CanelledQuote*/	when RevisionStatus = 1 then 0
					else AgreementPrice
				end
			   ) as BranchPrice
		, sum(AgreementBilledAmount) as BranchBilled
		, min(Revision) as BranchFirstRevision
		, max(Revision) as BranchLastRevision
		, min(RevisionStatus) as BranchFirstStatus
		, max(RevisionStatus) as BranchLastStatus	
		, max(Revision) as LastRevisionInBranch
							
	From
		#AgreementRevisionBranches a
	group by
		a.SMCo
		, a.Agreement
		, a.RevisionBranch						
)

SELECT 
	Revs.*
	, Branches.BranchEffectiveDate
	, LastRevDates.DateTerminated as BranchTerminatedDate
	, LastRevDates.ExpirationDate as BranchExpirationDate
	, Branches.BranchCancelledDate
	, Branches.BranchPrice
	, Branches.BranchBilled
	, Branches.BranchFirstRevision
	, Branches.BranchLastRevision
	, Branches.BranchFirstStatus
	, Branches.BranchLastStatus
	, Branches.LastRevisionInBranch

From 
	#AgreementRevisionBranches Revs
left outer Join
	CTE_Branches Branches on
		Revs.SMCo = Branches.SMCo
		and Revs.Agreement = Branches.Agreement
		and Revs.RevisionBranch = Branches.RevisionBranch
left outer join
	#AgreementRevisionBranches LastRevDates on 
		Revs.SMCo = LastRevDates.SMCo
		and Revs.Agreement = LastRevDates.Agreement
		and Revs.RevisionBranch = LastRevDates.RevisionBranch
		and Branches.LastRevisionInBranch = LastRevDates.Revision

--clean up your toys
DROP TABLE #AgreementRevisionBranches


	
GO
GRANT EXECUTE ON  [dbo].[vrptSMAgreementRevBranches] TO [public]
GO
