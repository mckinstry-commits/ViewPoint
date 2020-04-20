using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;
using System.Security.Principal;
using McKinstry.ViewPoint.Data;

namespace McKinstry.ViewPoint.Services
{
    
    public class ContractService : IContractService
    {
        ViewpointEntities dbContext;
        Subcontract sc = null;
        List<Subcontract> scs = null;

        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public string GetData(int value)
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                return string.Format("You entered: {0}", WindowsIdentity.GetCurrent().Name);
            }
            
        }


        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public List<Subcontract> getContract(string SubContractNumber)
        {
            if (SubContractNumber == ""  || SubContractNumber == null) return null;
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbContext = new ViewpointEntities())
                {
                    if (dbContext.Connection.State != System.Data.ConnectionState.Open)
                    {
                        dbContext.Connection.Open();
                        scs = dbContext.Subcontracts.Where(s => s.SL == SubContractNumber).ToList();
                    }

                    return scs;
                }
            }
        }

        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public List<DocLocation> getLocations()
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbContext = new ViewpointEntities())
                {
                    if (dbContext.Connection.State != System.Data.ConnectionState.Open)
                    {
                        dbContext.Connection.Open();
                        return dbContext.DocLocations.ToList<DocLocation>();
                    }
                    else
                        return null;
                }
            }
        }

        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public List<Company> getCompanies()
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbContext = new ViewpointEntities())
                {
                    if (dbContext.Connection.State != System.Data.ConnectionState.Open)
                    {
                        dbContext.Connection.Open();
                        return dbContext.Companies.ToList<Company>();
                    }
                    else
                        return null;
                }
            }
        }

        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public List<MasterContract> getMasterContract(string VendorNumber, string CompanyNumber,string VendorGroup)
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbContext = new ViewpointEntities())
                {
                    if (dbContext.Connection.State != System.Data.ConnectionState.Open)
                    {
                        int iCompany = int.Parse(CompanyNumber);
                        int iVendorNumber = int.Parse(VendorNumber);
                        Int16 iVendorGroup = Int16.Parse(VendorGroup);

                        dbContext.Connection.Open();
                        return dbContext.MasterContracts.Where(m => m.Vendor == iVendorNumber && m.VendorGroup == iVendorGroup && m.CompanyNumber == iCompany).ToList();
                    }
                    else
                        return null;
                }
            }

        }

        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public List<SubcontractCO> getSubcontractCOs(string SubcontractNumber, string CO)
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbContext = new ViewpointEntities())
                {
                    if (dbContext.Connection.State != System.Data.ConnectionState.Open)
                    {
                        Int16 iCO = Int16.Parse(CO);
                        dbContext.Connection.Open();
                        return dbContext.SubcontractCOes.Where(co => co.SL == SubcontractNumber && co.SubCO == iCO).ToList();
                    }
                    else
                        return null;
                }
            }

        }
    }
}
