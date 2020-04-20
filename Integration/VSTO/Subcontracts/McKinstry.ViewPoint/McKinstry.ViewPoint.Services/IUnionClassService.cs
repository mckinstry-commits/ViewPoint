using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;

using McKinstry.ViewPoint.Data;
namespace McKinstry.ViewPoint.Services
{
    [ServiceContract]
    public interface IUnionClassService
    {

        [OperationContract]
        void AddUpdateCraftClass(List<CraftInfo> craftclasses);

        [OperationContract]
        void AddUpdateDeductions(List<Deduction> deduction);

        [OperationContract]
        void AddUpdateEarnings(List<Earning> earnings);

        [OperationContract]
        void AddUpdateShiftRate(List<ShiftRate> shiftrates);

        [OperationContract]
        List<MasterEarning> GetMasterEarnings();

        [OperationContract]
        List<MasterDeduction> GetMasterDeductions();

        [OperationContract]
        List<MasterCraft> GetMasterCrafts();
    }
}
