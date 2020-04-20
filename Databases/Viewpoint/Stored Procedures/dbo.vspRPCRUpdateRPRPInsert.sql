SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspRPCRUpdateRPRPInsert] 
/*	
	*********************************************************************
	* adds a new report parameter into the criteria table.
	* used by form RPRT
	*		MODIFIED:  Terry L 04/20/05 - Modified for Viewpoint 6
			ALLENN 04/12/02 - Increased Description field to 1000. issue 16323
	*		allenn 10/10/02 - issue 17681 added default InputType and InputLength
	*		DANF 11/25/2003 - Added isnull check and with (nolock).
	*		RBT  02/13/2004 - #23183, add default precision for numeric types.
	*		CC	 10/14/2008 - #128631 - Added optional default value parameter
   *********************************************************************
*/
   (@ReportID int =null, @ParameterName varchar(30)=null,
    @CRDataType char(1)=null, @Description varchar(256)=null, @DefaultValue varchar(60) = null, @msg varchar(256) output)
   as
   set nocount on
   declare  @rcode int,  @DisplaySeq tinyint, @BidtekType varchar(20), @InputMask varchar(30),
   	@InputType tinyint, @InputLength smallint, @NumPrec tinyint

  select @rcode = 0

   if @ReportID is null 
   Begin
		select @msg='No Report ID supplied', @rcode=1
   		goto vspexit 
   	End

	if @ParameterName is null 
	Begin
   		select @msg='No Parameter Name supplied', @rcode=1
   		goto vspexit 
   	End

    if @CRDataType not in ('S','N','D','M') 
	Begin
   		select @msg='Data types must be either S/N/D/M', @rcode=1
   		goto vspexit 
    End

	if @DisplaySeq is null 
		Begin
			select @DisplaySeq=IsNull(Max(DisplaySeq),0)+1
   			from dbo.RPRPShared with (nolock) where ReportID=@ReportID
		End

--Company
if @CRDataType='N' and CHARINDEX('CCO',UPPER(@ParameterName))>0
   	select @BidtekType='bHQCo'
 if @CRDataType='N' and CHARINDEX('COMPANY',UPPER(@ParameterName))>0
   	select @BidtekType='bHQCo'

--Job Cost
--Contract
if @CRDataType='S' and CHARINDEX('CONTRACT',UPPER(@ParameterName))>0
   	select @BidtekType='bContract' 
--Job
if @CRDataType='S' and CHARINDEX('JOB',UPPER(@ParameterName))>0
   	select @BidtekType='bJob' 
--Phase
if @CRDataType='S' and CHARINDEX('PHASE',UPPER(@ParameterName))>0
   	select @BidtekType='bPhase'

--Project 
if @CRDataType='S' and CHARINDEX('PROJECT',UPPER(@ParameterName))>0
   	select @BidtekType='bProject' 

--Project Manager
if @CRDataType='N' and CHARINDEX('PROJMGR',UPPER(@ParameterName))>0
   	select @BidtekType='bProjectMgr' 
if @CRDataType='N' and CHARINDEX('PROJECTMGR',UPPER(@ParameterName))>0
   	select @BidtekType='bProjectMgr' 
if @CRDataType='N' and CHARINDEX('PROJECTMGR',UPPER(@ParameterName))>0
   	select @BidtekType='bProjectMgr' 

--JB Processing Group
if @CRDataType='S' and CHARINDEX('PROCESSINGGROUP',UPPER(@ParameterName))>0
   	select @BidtekType='bProcessGroup' 
if @CRDataType='S' and CHARINDEX('PROCGROUP',UPPER(@ParameterName))>0
   	select @BidtekType='bProcessGroup' 
if @CRDataType='S' and CHARINDEX('PROCESSGROUP',UPPER(@ParameterName))>0
   	select @BidtekType='bProcessGroup' 

--Vendor
if @CRDataType='N' and CHARINDEX('VENDOR',UPPER(@ParameterName))>0
   	select @BidtekType='bVendor' 

--VendorSortName
if @CRDataType='S' and CHARINDEX('VENDORSORTNAME',UPPER(@ParameterName))>0
   	select @BidtekType='bVendSortName' 
if @CRDataType='S' and CHARINDEX('VENDSORTNAME',UPPER(@ParameterName))>0
   	select @BidtekType='bVendSortName' 

--APRef
if @CRDataType='N' and CHARINDEX('APREF',UPPER(@ParameterName))>0
   	select @BidtekType='bAPREF' 

--Customer
if @CRDataType='N' and CHARINDEX('CUSTOMER',UPPER(@ParameterName))>0
   	select @BidtekType='bCustomer' 

--CustomerSortName
if @CRDataType='S' and CHARINDEX('CUSTSORTNAME',UPPER(@ParameterName))>0
   	select @BidtekType='bCustSortName' 
if @CRDataType='S' and CHARINDEX('CUSTNAME',UPPER(@ParameterName))>0
   	select @BidtekType='bCustSortName' 


--PRGroup
if @CRDataType='N' and CHARINDEX('PRGROUP',UPPER(@ParameterName))>0
   	select @BidtekType='bPRGroup' 
if @CRDataType='N' and CHARINDEX('PRGRP',UPPER(@ParameterName))>0
   	select @BidtekType='bPRGroup' 

--PREndDate
if @CRDataType='N' and CHARINDEX('PRENDDATE',UPPER(@ParameterName))>0
   	select @BidtekType='bPREndDate' 

--Employee
if @CRDataType='N' and CHARINDEX('EMPLOYEE',UPPER(@ParameterName))>0
   	select @BidtekType='bEmployee' 

--EmployeeSortName
if @CRDataType='S' and CHARINDEX('EMPLOYEESORTNAME',UPPER(@ParameterName))>0
   	select @BidtekType='bEmpSortName' 
if @CRDataType='S' and CHARINDEX('EMPSORTNAME',UPPER(@ParameterName))>0
   	select @BidtekType='bEmpSortName'
 
--HRRef
if @CRDataType='N' and CHARINDEX('HRREF',UPPER(@ParameterName))>0
   	select @BidtekType='bHRREF' 

--CMAcct
if @CRDataType='N' and CHARINDEX('CMACCT',UPPER(@ParameterName))>0
   	select @BidtekType='bCMAcct' 
if @CRDataType='N' and CHARINDEX('CMACCNT',UPPER(@ParameterName))>0
   	select @BidtekType='bCMAcct' 
if @CRDataType='N' and CHARINDEX('CMACCOUNT',UPPER(@ParameterName))>0
   	select @BidtekType='bCMAcct' 

--CMRef
if @CRDataType='S' and CHARINDEX('CMREF',UPPER(@ParameterName))>0
   	select @BidtekType='bCMRef' 

--GLAcct
if @CRDataType='S' and CHARINDEX('GLACCT',UPPER(@ParameterName))>0
   	select @BidtekType='bGLAcct' 
if @CRDataType='S' and CHARINDEX('GLACCNT',UPPER(@ParameterName))>0
   	select @BidtekType='bGLAcct' 
if @CRDataType='S' and CHARINDEX('GLACCOUNT',UPPER(@ParameterName))>0
   	select @BidtekType='bGLAcct' 

--MS Ticket
if @CRDataType='S' and CHARINDEX('TICKET',UPPER(@ParameterName))>0
   	select @BidtekType='bTicket' 

--State
if @CRDataType='S' and CHARINDEX('STATE',UPPER(@ParameterName))>0
   	select @BidtekType='bState' 
--Zip
if @CRDataType='S' and CHARINDEX('ZIP',UPPER(@ParameterName))>0
   	select @BidtekType='bZip' 

--DATES/MONTHS/WEEKS
--Defaults for Month
if @CRDataType='D'  and CHARINDEX('MTH',UPPER(@ParameterName))>0
   	select @BidtekType='bMonth', @CRDataType = 'M'
if @CRDataType='D'  and CHARINDEX('MNTH',UPPER(@ParameterName))>0
   	select @BidtekType='bMonth' , @CRDataType = 'M'
if @CRDataType='D'  and CHARINDEX('MONTH',UPPER(@ParameterName))>0
   	select @BidtekType='bMonth' , @CRDataType = 'M'

--Default for Week
if @CRDataType='D' and CHARINDEX('Week',UPPER(@ParameterName))>0
   	select @BidtekType='bDate'

--Date
if @CRDataType='D' and CHARINDEX('DATE',UPPER(@ParameterName))>0
   	select @BidtekType='bDate' 



--Bidtek Type is Null  
   --issue 17681 - add default values to RPRP table if datatype is a string
   if @CRDataType = 'S' and @BidtekType is null
  	select  @InputLength = 30, @InputType = 0

   --issue 23183 - add default precision for numeric datatypes (not company)
   if @CRDataType = 'N' and @BidtekType is null
  	select @NumPrec = 2, @InputType = 1	--default precision to integer (per Nadine)
  
   if @CRDataType = 'D' and @BidtekType is null
  	select   @InputType = 2	--default precision to integer (per Nadine)

  if @CRDataType = 'M' and @BidtekType is null
  	select  @InputType = 3	


	If  (select count(*) from dbo.RPRPShared  with(nolock) where ReportID=@ReportID and ParameterName=@ParameterName)=0
	begin
  		insert into dbo.RPRPShared (ReportID, ParameterName, DisplaySeq, ReportDatatype, Description, Datatype,InputType, InputMask, InputLength, Prec,ActiveLookup, LookupSeq, ParamRequired, ParameterDefault)
  		select @ReportID, @ParameterName, @DisplaySeq, @CRDataType, @Description, @BidtekType, @InputType, @InputMask, @InputLength, @NumPrec,'Y',0,'N', @DefaultValue
  		if @@rowcount<>1 
		Begin
			select @msg = isnull(@msg,'') + ' - error on insert, cannot insert Parameter!',@rcode=1
  			goto vspexit
		end
	End

vspexit:
return @rcode 


GO
GRANT EXECUTE ON  [dbo].[vspRPCRUpdateRPRPInsert] TO [public]
GO
