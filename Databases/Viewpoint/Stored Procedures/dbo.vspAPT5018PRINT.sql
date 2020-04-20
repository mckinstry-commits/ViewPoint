SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         proc [dbo].[vspAPT5018PRINT]      
    /************************************      
    * Created: MV 12/14/09 - #133633      
    * Modified: MV 06/18/12 - TK15758 restrict Amended refiling by bAPVM.V1099YN = 'Y' (vendor is still subject to T5)       
    *      - TK-16658 select T5ParterFINm, T5SocInsNbr and T5FirstName from APVM for Types O, C and All  
	*	   - TK-16454 07/30/2012 DML :: added v.Type 'C' to @reporttype = 'A' = DML
	*	   - TK-16445 07/30/2012 DML :: added column 'CalcdNo' to combine Corporation / Partnership / Individual IDs			
    * Report SP to print Canadian T5018      
    *      
    ***********************************/      
    (@co bCompany, @perenddate bDate, @reporttype char(1))      
        
   as      
   set nocount on      
        
 if @reporttype = 'A' --Amended refiling      
  begin      
  select isnull(c.Name,'')'HQName',isnull(c.Address,'') 'HQAddress', isnull(c.City,'') 'HQCity', isnull(c.State,'') 'HQState',      
   isnull(c.Country,'') 'HQCountry', isnull(c.Zip,'') 'HQPostal', isnull(c.FedTaxId,'') 'HQBusNbr',isnull(v.Name,'') 'VMName',      
   isnull(v.Address,'') 'VMAddress', isnull(v.City,'') 'VMCity', isnull(v.State,'') 'VMState', isnull(v.Zip,'') 'VMPostal',      
   isnull(v.Country,'') 'VMCountry', isnull(v.T5BusTypeCode,'') 'VMBusTypeCode', isnull(v.T5BusinessNbr,'') 'VMBusinessNbr',      
   isnull(v.T5PartnerFIN,'') 'VMPartnerFIN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', isnull(v.T5FirstName,'') 'VMFirstName',      
   isnull(v.T5MiddleInit,'') 'VMMiddleInit', isnull(v.T5LastName,'') 'VMLastName', isnull(t.OrigAmount,'0') 'OrigAmount',      
   isnull(t.Amount,'0') 'AmendedAmount', isnull(t.Type,'') 'T5Type', isnull(t.RefilingYN, 'N') 'RefilingYN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', 'CalcdNo' = case (v.T5BusTypeCode)  
   	when 'C' then v.T5BusinessNbr 
	when 'P' then v.T5PartnerFIN 
	when 'I' then v.T5SocInsNbr 
	else '' 
	end     
  From dbo.APT5 t (nolock)      
  join dbo.HQCO c (nolock) on c.HQCo=t.APCo      
  join dbo.APVM v (nolock) on c.VendorGroup=v.VendorGroup and t.Vendor=v.Vendor   
    where t.APCo=@co and @perenddate=t.PeriodEndDate and t.RefilingYN='Y' and t.Type in ('A','C') AND v.V1099YN = 'Y'      
  end      
    
 if @reporttype = 'O' --Original refiling      
  begin       
  select isnull(c.Name,'')'HQName',isnull(c.Address,'') 'HQAddress', isnull(c.City,'') 'HQCity', isnull(c.State,'') 'HQState',      
   isnull(c.Country,'') 'HQCountry', isnull(c.Zip,'') 'HQPostal', isnull(c.FedTaxId,'') 'HQBusNbr',isnull(v.Name,'') 'VMName',      
   isnull(v.Address,'') 'VMAddress', isnull(v.City,'') 'VMCity', isnull(v.State,'') 'VMState', isnull(v.Zip,'') 'VMPostal',      
   isnull(v.Country,'') 'VMCountry', isnull(v.T5BusTypeCode,'') 'VMBusTypeCode', isnull(v.T5BusinessNbr,'') 'VMBusinessNbr',   
   isnull(v.T5PartnerFIN,'') 'VMPartnerFIN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', isnull(v.T5FirstName,'') 'VMFirstName',      
   isnull(v.T5MiddleInit,'') 'VMMiddleInit', isnull(v.T5LastName,'') 'VMLastName', isnull(t.OrigAmount,'0') 'OrigAmount',      
   isnull(t.Amount,'0') 'AmendedAmount', isnull(t.Type,'') 'T5Type', isnull(t.RefilingYN, 'N') 'RefilingYN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', 'CalcdNo' = case (v.T5BusTypeCode)  
   	when 'C' then v.T5BusinessNbr 
	when 'P' then v.T5PartnerFIN 
	when 'I' then v.T5SocInsNbr 
	else '' 
	end      
  From dbo.APT5 t (nolock)      
  join dbo.HQCO c (nolock) on c.HQCo=t.APCo      
  join dbo.APVM v (nolock) on c.VendorGroup=v.VendorGroup and t.Vendor=v.Vendor      
  where t.APCo=@co and @perenddate=t.PeriodEndDate and t.RefilingYN='N' and t.Type='O'      
  end      
    
 if @reporttype = 'C' --Cancelled refiling      
  begin      
  select isnull(c.Name,'')'HQName',isnull(c.Address,'') 'HQAddress', isnull(c.City,'') 'HQCity', isnull(c.State,'') 'HQState',      
   isnull(c.Country,'') 'HQCountry', isnull(c.Zip,'') 'HQPostal', isnull(c.FedTaxId,'') 'HQBusNbr',isnull(v.Name,'') 'VMName',      
   isnull(v.Address,'') 'VMAddress', isnull(v.City,'') 'VMCity', isnull(v.State,'') 'VMState', isnull(v.Zip,'') 'VMPostal',      
   isnull(v.Country,'') 'VMCountry', isnull(v.T5BusTypeCode,'') 'VMBusTypeCode', isnull(v.T5BusinessNbr,'') 'VMBusinessNbr',  
   isnull(v.T5PartnerFIN,'') 'VMPartnerFIN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', isnull(v.T5FirstName,'') 'VMFirstName',      
   isnull(v.T5MiddleInit,'') 'VMMiddleInit', isnull(v.T5LastName,'') 'VMLastName', isnull(t.OrigAmount,'0') 'OrigAmount',      
   isnull(t.Amount,'0') 'AmendedAmount', isnull(t.Type,'') 'T5Type', isnull(t.RefilingYN, 'N') 'RefilingYN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', 'CalcdNo' = case (v.T5BusTypeCode)  
   	when 'C' then v.T5BusinessNbr 
	when 'P' then v.T5PartnerFIN 
	when 'I' then v.T5SocInsNbr 
	else '' 
	end      
  From dbo.APT5 t (nolock)      
  join dbo.HQCO c (nolock) on c.HQCo=t.APCo      
  join dbo.APVM v (nolock) on c.VendorGroup=v.VendorGroup and t.Vendor=v.Vendor      
  where t.APCo=@co and @perenddate=t.PeriodEndDate and t.RefilingYN='Y' and t.Type='C'      
  end      
    
   if @reporttype = 'S' --All (S)lips      
  begin       
  select isnull(c.Name,'')'HQName',isnull(c.Address,'') 'HQAddress', isnull(c.City,'') 'HQCity', isnull(c.State,'') 'HQState',      
   isnull(c.Country,'') 'HQCountry', isnull(c.Zip,'') 'HQPostal', isnull(c.FedTaxId,'') 'HQBusNbr',isnull(v.Name,'') 'VMName',      
   isnull(v.Address,'') 'VMAddress', isnull(v.City,'') 'VMCity', isnull(v.State,'') 'VMState', isnull(v.Zip,'') 'VMPostal',      
   isnull(v.Country,'') 'VMCountry', isnull(v.T5BusTypeCode,'') 'VMBusTypeCode', isnull(v.T5BusinessNbr,'') 'VMBusinessNbr',  
   isnull(v.T5PartnerFIN,'') 'VMPartnerFIN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', isnull(v.T5FirstName,'') 'VMFirstName',      
   isnull(v.T5MiddleInit,'') 'VMMiddleInit', isnull(v.T5LastName,'') 'VMLastName', isnull(t.OrigAmount,'0') 'OrigAmount',      
   isnull(t.Amount,'0') 'AmendedAmount', isnull(t.Type,'') 'T5Type', isnull(t.RefilingYN, 'N') 'RefilingYN', isnull(v.T5SocInsNbr,'') 'VMSocInsNbr', 'CalcdNo' = case (v.T5BusTypeCode)  
   	when 'C' then v.T5BusinessNbr 
	when 'P' then v.T5PartnerFIN 
	when 'I' then v.T5SocInsNbr 
	else '' 
	end      
  From dbo.APT5 t (nolock)      
  join dbo.HQCO c (nolock) on c.HQCo=t.APCo      
  join dbo.APVM v (nolock) on c.VendorGroup=v.VendorGroup and t.Vendor=v.Vendor      
  where t.APCo=@co and @perenddate=t.PeriodEndDate       
  end      
      
 return       
      
      
      
      
  
GO
GRANT EXECUTE ON  [dbo].[vspAPT5018PRINT] TO [public]
GO
