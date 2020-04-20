using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;

using McKinstry.ViewPoint.Data;
namespace McKinstry.ViewPoint.Services
{
    // NOTE: You can use the "Rename" command on the "Refactor" menu to change the class name "UnionClassService" in code, svc and config file together.
    public class UnionClassService : IUnionClassService
    {
        ViewpointEntities dbCotext = null;
        
        public List<CraftInfo> getCrafts()
        {
            return null;
        }

        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public void AddUpdateCraftClass(List<CraftInfo> craftclasses)
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbCotext = new ViewpointEntities())
                {
                    foreach (CraftInfo ci in craftclasses)
                    {
                        var obj = dbCotext.CraftInfoes.Where(c => c.PRCo == ci.PRCo &&
                                                                  c.Class == ci.Class &&
                                                                  c.Craft == ci.Craft).FirstOrDefault();

                        if (obj == null)
                        {
                            dbCotext.CraftInfoes.AddObject(ci);
                        }
                        else
                        {
                            obj.Description = ci.Description;
                            obj.Notes = ci.Notes;
                            dbCotext.SaveChanges();
                        }

                    }
                    try
                    {
                        dbCotext.SaveChanges();
                    }
                    catch (Exception e)
                    {
                        throw e;
                    }
                }
            }
        }
        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public void AddUpdateDeductions(List<Deduction> exceldeductions)
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbCotext = new ViewpointEntities())
                {
                    foreach (Deduction deduction in exceldeductions)
                    {
                        var obj = dbCotext.Deductions.Where(d => d.PRCo == deduction.PRCo &&
                                                                  d.Class == deduction.Class &&
                                                                  d.Craft == deduction.Craft &&
                                                                  d.DLCode == deduction.DLCode &&
                                                                  d.Factor == deduction.Factor).FirstOrDefault();


                        if (obj == null)
                        {
                            deduction.OldRate = deduction.NewRate;
                            dbCotext.Deductions.AddObject(deduction);
                        }
                        else
                        {
                            if (deduction.KeyID == 0)
                            {
                                if (obj.NewRate != deduction.NewRate)
                                {
                                    obj.OldRate = obj.NewRate;
                                    obj.NewRate = deduction.NewRate;
                                    //obj.Factor = deduction.Factor;
                                }
                            }
                            else
                            {
                                obj.NewRate = deduction.NewRate;
                            }
                        }
                        try
                        {
                            dbCotext.SaveChanges();
                        }
                        catch (Exception e)
                        {
                            throw e;
                        }
                    }
                }
            }
        }

        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public void AddUpdateEarnings(List<Earning> earnings)
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbCotext = new ViewpointEntities())
                {
                    foreach (Earning e in earnings)
                    {
                        var obj = dbCotext.Earnings.Where(er => er.PRCo == e.PRCo &&
                                                                  er.Class == e.Class &&
                                                                  er.Craft == e.Craft &&
                                                                  er.Factor == e.Factor &&
                                                                  er.EarnCode == e.EarnCode).FirstOrDefault();


                        if (obj == null)
                        {
                            e.OldRate = e.NewRate;
                            dbCotext.Earnings.AddObject(e);
                        }
                        else
                        {
                            if (e.KeyID == 0)  //Correction is set to "No" = 0, "Yes" = 1
                            {
                                if (obj.NewRate != e.NewRate)
                                {
                                    obj.OldRate = obj.NewRate;
                                    obj.NewRate = e.NewRate;
                                }
                            }
                            else
                            {
                                obj.NewRate = e.NewRate;
                            }
                        }
                        try
                        {
                            dbCotext.SaveChanges();
                        }
                        catch (Exception ex)
                        {
                            throw ex;
                        }
                    }
                }
            }

        }

        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public void AddUpdateShiftRate(List<ShiftRate> shiftrates)
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbCotext = new ViewpointEntities())
                {
                    foreach (ShiftRate sr in shiftrates)
                    {
                        var obj = dbCotext.ShiftRates.Where(s => s.PRCo == sr.PRCo && s.Class == sr.Class && s.Craft == sr.Craft && s.Shift == sr.Shift).FirstOrDefault();
                        if (obj != null)
                        {
                            if (sr.KeyID == 0)  //Correction is set to "No" = 0, "Yes" = 1
                            {
                                if (obj.NewRate != sr.NewRate)
                                {
                                    obj.OldRate = obj.NewRate;
                                    obj.NewRate = sr.NewRate;
                                }
                            }
                            else
                            {
                                obj.NewRate = sr.NewRate;
                            }
                            
                        }
                        else
                        {
                            sr.OldRate = sr.NewRate;
                            dbCotext.ShiftRates.AddObject(sr);
                        }
                    }
                    try
                    {
                        dbCotext.SaveChanges();
                    }
                    catch (Exception e)
                    {
                        throw e;
                    }
                }
            }
             
        }
        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public List<MasterEarning> GetMasterEarnings()
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbCotext = new ViewpointEntities())
                {
                    return dbCotext.GetMasterEarnings().ToList();
                }
            }
        }
        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public List<MasterDeduction> GetMasterDeductions()
        {
            using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
            {
                using (dbCotext = new ViewpointEntities())
                {
                    return dbCotext.GetMasterDeductions().ToList();
                }
            }
        }
        [OperationBehavior(Impersonation = ImpersonationOption.Allowed)]
        public List<MasterCraft> GetMasterCrafts()
         {
             using (ServiceSecurityContext.Current.WindowsIdentity.Impersonate())
             {
                 using (dbCotext = new ViewpointEntities())
                 {
                             
                     return dbCotext.MasterCrafts.ToList();
                 }
             }
         }
    }

  

}
