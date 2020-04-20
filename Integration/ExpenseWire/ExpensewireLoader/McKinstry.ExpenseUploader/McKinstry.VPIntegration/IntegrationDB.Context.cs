//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Data.Objects;
using System.Data.EntityClient;

namespace McKinstry.VPIntegration
{
    public partial class MCK_INTEGRATIONEntities : ObjectContext
    {
        public const string ConnectionString = "name=MCK_INTEGRATIONEntities";
        public const string ContainerName = "MCK_INTEGRATIONEntities";
    
        #region Constructors
    
        public MCK_INTEGRATIONEntities()
            : base(ConnectionString, ContainerName)
        {
            this.ContextOptions.LazyLoadingEnabled = true;
        }
    
        public MCK_INTEGRATIONEntities(string connectionString)
            : base(connectionString, ContainerName)
        {
            this.ContextOptions.LazyLoadingEnabled = true;
        }
    
        public MCK_INTEGRATIONEntities(EntityConnection connection)
            : base(connection, ContainerName)
        {
            this.ContextOptions.LazyLoadingEnabled = true;
        }
    
        #endregion
    
        #region ObjectSet Properties
    
        public ObjectSet<ExpenseDetail> ExpenseDetails
        {
            get { return _expenseDetails  ?? (_expenseDetails = CreateObjectSet<ExpenseDetail>("ExpenseDetails")); }
        }
        private ObjectSet<ExpenseDetail> _expenseDetails;
    
        public ObjectSet<JobPhaseCodeInfo> JobPhaseCodeInfoes
        {
            get { return _jobPhaseCodeInfoes  ?? (_jobPhaseCodeInfoes = CreateObjectSet<JobPhaseCodeInfo>("JobPhaseCodeInfoes")); }
        }
        private ObjectSet<JobPhaseCodeInfo> _jobPhaseCodeInfoes;
    
        public ObjectSet<TimeSheet> TimeSheets
        {
            get { return _timeSheets  ?? (_timeSheets = CreateObjectSet<TimeSheet>("TimeSheets")); }
        }
        private ObjectSet<TimeSheet> _timeSheets;
    
        public ObjectSet<EWCheckNumber> EWCheckNumbers
        {
            get { return _eWCheckNumbers  ?? (_eWCheckNumbers = CreateObjectSet<EWCheckNumber>("EWCheckNumbers")); }
        }
        private ObjectSet<EWCheckNumber> _eWCheckNumbers;
    
        public ObjectSet<ExpenseHeader> ExpenseHeaders
        {
            get { return _expenseHeaders  ?? (_expenseHeaders = CreateObjectSet<ExpenseHeader>("ExpenseHeaders")); }
        }
        private ObjectSet<ExpenseHeader> _expenseHeaders;
    
        public ObjectSet<EmployeeInfo> EmployeeInfoes
        {
            get { return _employeeInfoes  ?? (_employeeInfoes = CreateObjectSet<EmployeeInfo>("EmployeeInfoes")); }
        }
        private ObjectSet<EmployeeInfo> _employeeInfoes;
    
        public ObjectSet<EmployeeVendorInfo> EmployeeVendorInfoes
        {
            get { return _employeeVendorInfoes  ?? (_employeeVendorInfoes = CreateObjectSet<EmployeeVendorInfo>("EmployeeVendorInfoes")); }
        }
        private ObjectSet<EmployeeVendorInfo> _employeeVendorInfoes;

        #endregion

        #region Function Imports
        public ObjectResult<sp_ExtractTimesheets_Result> sp_ExtractTimesheets()
        {
            return base.ExecuteFunction<sp_ExtractTimesheets_Result>("sp_ExtractTimesheets");
        }

        #endregion

    }
}