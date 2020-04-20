//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Collections.Specialized;

namespace McKinstry.VPIntegration
{
    public partial class ExpenseHeader
    {
        #region Primitive Properties
    
        public virtual string ExpenseID
        {
            get;
            set;
        }
    
        public virtual string EmployeeNumber
        {
            get;
            set;
        }
    
        public virtual string ExpenseTitle
        {
            get;
            set;
        }
    
        public virtual Nullable<byte> EmployeeCompany
        {
            get;
            set;
        }
    
        public virtual string EmployeeVendorNumber
        {
            get;
            set;
        }
    
        public virtual string EmployeeGLDept
        {
            get;
            set;
        }
    
        public virtual string InvoiceNumber
        {
            get;
            set;
        }
    
        public virtual Nullable<System.DateTime> DueDate
        {
            get;
            set;
        }
    
        public virtual Nullable<System.DateTime> CreatedDate
        {
            get;
            set;
        }
    
        public virtual Nullable<decimal> ExpenseTotal
        {
            get;
            set;
        }
    
        public virtual string ExpenseWireBatchID
        {
            get;
            set;
        }
    
        public virtual string ProcessStatus
        {
            get;
            set;
        }
    
        public virtual short MailCounter
        {
            get;
            set;
        }

        #endregion
    }
}