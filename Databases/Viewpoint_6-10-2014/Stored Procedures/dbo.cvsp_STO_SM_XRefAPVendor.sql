SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright Â© 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	Populate SM Vendor to Cross Reference Table (budXRefAPVendor)
	Created: 11/27/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 	
					
	Notes:	This procedure is to be run after a data refresh to add any
	missing vendors. Cross Reference tables are needed when the STO data
	uses alpha characters in the Vendor ID field and thus, the Vendor
	id for Viewpoint needs to be changed to numeric and the client wants
	to assign specific numbers or control of the assigned id's or to control
	the ActiveYN status.
		
**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefAPVendor] 
(@VendorGroup tinyint --, @DeleteXRefVendorYN char(1)
,@RefreshVendorNameYN char(1), @UseStartNoYN char(1), @StartNo int)

AS 


/** BACKUP AND DELETE DATA IN budXRefAPVendor TABLE **/
IF OBJECT_ID('budXRefAPVendor_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefAPVendor_bak
END;
BEGIN
	SELECT * INTO budXRefAPVendor_bak FROM budXRefAPVendor
END;

--if @DeleteXRefVendorYN IN('Y','y')
--begin
--	delete budXRefAPVendor where VendorGroup=@VendorGroup
--end;


/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int
set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefAPVendor) 

declare @NextNo bVendor	
set @NextNo=ISNULL((select MAX(NewVendorID) from budXRefAPVendor where VendorGroup=@VendorGroup),@StartNo) 


/** UPDATE NewYN='N' FOR REFRESH **/
--update budXRefAPVendor
--set NewYN='N'
--where VendorGroup=@VendorGroup and NewYN='Y';


/** INSERT/UPDATE AP VENDOR XReference TABLE **/
IF OBJECT_ID('budXRefAPVendor') IS NOT NULL
BEGIN
	INSERT budXRefAPVendor
		(
		 Seq
		,ActiveYN
		,Name
		,NewVendorID
		,NewYN
		,OldVendorID
		,VendorGroup
		,Notes
		)
--declare @VendorGroup bGroup set @VendorGroup=
	SELECT 
		 Seq=@MAXSeq+ROW_NUMBER() OVER (ORDER BY LTRIM(v.NAME))
		,ActiveYN='Y'
		,Name=v.NAME
		,NewVendorID= --NOTE: CANNOT EXCEED LENGTH OF 6
			CASE
				WHEN v.APVENDOR='ONETIME' THEN 0 --Set temporary ONETIME v.APVENDOR ID = 0
				WHEN v.APVENDOR<>'ONETIME' AND @UseStartNoYN IN('Y','y') 
					THEN @NextNo+ROW_NUMBER() OVER (ORDER BY LTRIM(v.NAME))
				WHEN v.APVENDOR<>'ONETIME' AND @UseStartNoYN NOT IN('Y','y') THEN
					CASE
						--Use Row Number for non numeric v.APVENDOR ID's
						WHEN ISNUMERIC(v.APVENDOR)=0 THEN 
							(select ISNULL(MAX(NewVendorID),0) from budXRefAPVendor)
							+ROW_NUMBER() OVER (ORDER BY LTRIM(v.NAME))
						--Use for numeric v.APVENDOR ID's
						ELSE 
							--Use number if less than 6 digits, removing leading zero.
							CASE WHEN LEN(v.APVENDOR)<7 THEN
								CASE --Must deal with v.APVENDOR ID's with leading 0, 001, 0001
									WHEN LEFT(v.APVENDOR,1)=0 THEN REPLACE(LTRIM(REPLACE(v.APVENDOR, '0', ' ')), ' ', '0')
									--Use the LTRIM string function to trim leading spaces
									--Lastly, replace all spaces back to 0  
									--This solution will only work if there are no spaces within the string									
									ELSE CAST(v.APVENDOR AS INT)
								END
								--If number greater than 6 digits, then assign new number.
								ELSE (select ISNULL(MAX(NewVendorID),0) from budXRefAPVendor)
									 +ROW_NUMBER() OVER (ORDER BY v.APVENDOR)
							END
					END
				END
		,NewYN='Y'
		,OldVendorID=v.APVENDOR
		,VendorGroup=@VendorGroup
		,Notes='SM VENDOR'
	--declare @VendorGroup bGroup set @VendorGroup=
	--select *
	from CV_TL_Source_SM.dbo.VENDOR v
	left join budXRefAPVendor x
		on x.VendorGroup=@VendorGroup AND x.OldVendorID=v.APVENDOR
	where x.OldVendorID is null and v.APVENDOR<>''
	order by LTRIM(v.NAME)
END;


/** REFRESH AP VENDOR NAME **/

if @RefreshVendorNameYN IN ('Y','y')
begin 
	update budXRefAPVendor
	set Name=v.NAME
	from budXRefAPVendor x
	inner join CV_TL_Source_SM.dbo.VENDOR v
		on x.VendorGroup=@VendorGroup and v.APVENDOR=x.OldVendorID
end;


/** RECORD COUNT **/
--declare @VendorGroup bGroup set @VendorGroup=
select COUNT(*) as XRVendorCount from budXRefAPVendor where VendorGroup=@VendorGroup;
select * from budXRefAPVendor where VendorGroup=@VendorGroup;

select COUNT(*) as STOSMVendorCount from CV_TL_Source_SM.dbo.VENDOR;
select * from CV_TL_Source_SM.dbo.VENDOR order by APVENDOR;

select COUNT(*) as APVendorCount from bAPVM where VendorGroup=@VendorGroup;
select * from bAPVM where VendorGroup=@VendorGroup;


/** DATA REVIEW **/
/*
select * from CV_TL_Source_SM.dbo.VENDOR where ISNUMERIC(Vendor)<>1 
select * from CV_TL_Source_SM.dbo.VENDOR where ISNUMERIC(Vendor)<>0 

declare @VendorGroup bGroup set @VendorGroup=
select NewVendorID
from dbo.budXRefAPVendor
where VendorGroup=@VendorGroup
group by NewVendorID
having COUNT(*)>1
*/

GO
