using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Globalization;


namespace McKinstry.ExpenseWire.Model
{
    #region "New Code"

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
    public partial class ExpenseWire
    {

        private ExpenseWireSendDataTransaction sendDataTransactionField;

        /// <remarks/>
        public ExpenseWireSendDataTransaction SendDataTransaction
        {
            get
            {
                return this.sendDataTransactionField;
            }
            set
            {
                this.sendDataTransactionField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransaction
    {

        private int sequenceNumberField;

        private int errorCodeField;

        private object errorMessageField;

        private ExpenseWireSendDataTransactionExpense expenseField;

        /// <remarks/>
        public int SequenceNumber
        {
            get
            {
                return this.sequenceNumberField;
            }
            set
            {
                this.sequenceNumberField = value;
            }
        }

        /// <remarks/>
        public int ErrorCode
        {
            get
            {
                return this.errorCodeField;
            }
            set
            {
                this.errorCodeField = value;
            }
        }

        /// <remarks/>
        public object ErrorMessage
        {
            get
            {
                return this.errorMessageField;
            }
            set
            {
                this.errorMessageField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpense Expense
        {
            get
            {
                return this.expenseField;
            }
            set
            {
                this.expenseField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpense
    {

        private ExpenseWireSendDataTransactionExpenseSearch searchField;

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearch Search
        {
            get
            {
                return this.searchField;
            }
            set
            {
                this.searchField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearch
    {

        private int sequenceNumberField;

        private int errorCodeField;

        private object errorMessageField;

        private ExpenseWireSendDataTransactionExpenseSearchExpense[] expenseField;

        /// <remarks/>
        public int SequenceNumber
        {
            get
            {
                return this.sequenceNumberField;
            }
            set
            {
                this.sequenceNumberField = value;
            }
        }

        /// <remarks/>
        public int ErrorCode
        {
            get
            {
                return this.errorCodeField;
            }
            set
            {
                this.errorCodeField = value;
            }
        }

        /// <remarks/>
        public object ErrorMessage
        {
            get
            {
                return this.errorMessageField;
            }
            set
            {
                this.errorMessageField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("Expense")]
        public ExpenseWireSendDataTransactionExpenseSearchExpense[] Expense
        {
            get
            {
                return this.expenseField;
            }
            set
            {
                this.expenseField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpense
    {

        private ExpenseWireSendDataTransactionExpenseSearchExpenseRef refField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseCustomer customerField;

        private object projectField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseUser userField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseApprovedBy approvedByField;

        private object needsApprovedByField;

        private ExpenseWireSendDataTransactionExpenseSearchExpensePaidBy paidByField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseDeniedBy deniedByField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseCurrency currencyField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseDepartment departmentField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseOrganization[] organizationsField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseBatch batchField;

        private int statusIDField;

        private string expenseTitleField;

        private decimal cashAdvancedField;

        private System.DateTime approvedDateField;

        private decimal amountDueField;

        private string deniedDateField;

        private decimal expenseTotalField;

        private String needsApprovedByAssignedDateField;

        private String paidDateField;

        private decimal paidAmountField;

        private string purposeField;

        private System.DateTime expenseStartDateField;

        private System.DateTime expenseEndDateField;

        private String checkNbrField;

        private decimal amountToPayField;

        private System.DateTime submittedDateField;

        private string submittedForPaymentDateField;

        private string paymentMethodField;

        private bool receiptsVerifiedField;

        private string receiptsVerifiedDateField;

        private string receiptsVerifiedbyUserField;

        private decimal totalReimbursableField;

        private decimal totalNotReimbursableField;

        private decimal totalEmployeeOwesField;

        private string externalIDField ="";

        private string createdUserField;

        private System.DateTime createdDateField;

        private string lastEditUserField;

        private System.DateTime lastEditDateField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetail[] expenseDetailField;

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseRef Ref
        {
            get
            {
                return this.refField;
            }
            set
            {
                this.refField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseCustomer Customer
        {
            get
            {
                return this.customerField;
            }
            set
            {
                this.customerField = value;
            }
        }

        /// <remarks/>
        public object Project
        {
            get
            {
                return this.projectField;
            }
            set
            {
                this.projectField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseUser User
        {
            get
            {
                return this.userField;
            }
            set
            {
                this.userField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseApprovedBy ApprovedBy
        {
            get
            {
                return this.approvedByField;
            }
            set
            {
                this.approvedByField = value;
            }
        }

        /// <remarks/>
        public object NeedsApprovedBy
        {
            get
            {
                return this.needsApprovedByField;
            }
            set
            {
                this.needsApprovedByField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpensePaidBy PaidBy
        {
            get
            {
                return this.paidByField;
            }
            set
            {
                this.paidByField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseDeniedBy DeniedBy
        {
            get
            {
                return this.deniedByField;
            }
            set
            {
                this.deniedByField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseCurrency Currency
        {
            get
            {
                return this.currencyField;
            }
            set
            {
                this.currencyField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseDepartment Department
        {
            get
            {
                return this.departmentField;
            }
            set
            {
                this.departmentField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlArrayItemAttribute("Organization", IsNullable = false)]
        public ExpenseWireSendDataTransactionExpenseSearchExpenseOrganization[] Organizations
        {
            get
            {
                return this.organizationsField;
            }
            set
            {
                this.organizationsField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseBatch Batch
        {
            get
            {
                return this.batchField;
            }
            set
            {
                this.batchField = value;
            }
        }

        /// <remarks/>
        public int StatusID
        {
            get
            {
                return this.statusIDField;
            }
            set
            {
                this.statusIDField = value;
            }
        }

        /// <remarks/>
        public string ExpenseTitle
        {
            get
            {
                return this.expenseTitleField;
            }
            set
            {
                this.expenseTitleField = value;
            }
        }

        /// <remarks/>
        public decimal CashAdvanced
        {
            get
            {
                return this.cashAdvancedField;
            }
            set
            {
                this.cashAdvancedField = value;
            }
        }

        /// <remarks/>
        public System.DateTime ApprovedDate
        {
            get
            {
                return this.approvedDateField;
            }
            set
            {
                this.approvedDateField = value;
            }
        }

        /// <remarks/>
        public decimal AmountDue
        {
            get
            {
                return this.amountDueField;
            }
            set
            {
                this.amountDueField = value;
            }
        }

        /// <remarks/>
        public string DeniedDate
        {
            get
            {
                return this.deniedDateField;
            }
            set
            {
                    this.deniedDateField = value;
            }
        }

        /// <remarks/>
        public decimal ExpenseTotal
        {
            get
            {
                return this.expenseTotalField;
            }
            set
            {
                this.expenseTotalField = value;
            }
        }

        /// <remarks/>
        public String NeedsApprovedByAssignedDate
        {
            get
            {
                return this.needsApprovedByAssignedDateField;
            }
            set
            {
                if (value != null)
                {
                    this.needsApprovedByAssignedDateField = value;
                }
            }

            //get
            //{
            //    if (this.needsApprovedByAssignedDateField != null)
            //    {
            //        return this.needsApprovedByAssignedDateField;
            //    }
            //    else
            //    {
            //        return DateTime.Today;
            //    }
            //    //return this.needsApprovedByAssignedDateField;
            //}
            //set
            //{
            //    if(value != null)
            //    this.needsApprovedByAssignedDateField = value;
            //}
        }

        /// <remarks/>
        public String PaidDate
        {
            get
            {
                return this.paidDateField;
            }
            set
            {
                if(value !=null)
                this.paidDateField = value;
            }
        }

        /// <remarks/>
        public decimal PaidAmount
        {
            get
            {
                return this.paidAmountField;
            }
            set
            {
                this.paidAmountField = value;
            }
        }

        /// <remarks/>
        public string Purpose
        {
            get
            {
                return this.purposeField;
            }
            set
            {
                this.purposeField = value;
            }
        }

        /// <remarks/>
        public System.DateTime ExpenseStartDate
        {
            get
            {
                return this.expenseStartDateField;
            }
            set
            {
                this.expenseStartDateField = value;
            }
        }

        /// <remarks/>
        public System.DateTime ExpenseEndDate
        {
            get
            {
                return this.expenseEndDateField;
            }
            set
            {
                this.expenseEndDateField = value;
            }
        }

        /// <remarks/>
        public String CheckNbr
        {
            get
            {
                return this.checkNbrField;
            }
            set
            {
                this.checkNbrField = value;
            }
        }

        /// <remarks/>
        public decimal AmountToPay
        {
            get
            {
                return this.amountToPayField;
            }
            set
            {
                this.amountToPayField = value;
            }
        }

        /// <remarks/>
        public System.DateTime SubmittedDate
        {
            get
            {
                return this.submittedDateField;
            }
            set
            {
                this.submittedDateField = value;
            }
        }

        /// <remarks/>
        public string SubmittedForPaymentDate
        {
            get
            {
                return this.submittedForPaymentDateField;
            }
            set
            {
                this.submittedForPaymentDateField = value;
            }
        }

        /// <remarks/>
        public string PaymentMethod
        {
            get
            {
                return this.paymentMethodField;
            }
            set
            {
                this.paymentMethodField = value;
            }
        }

        /// <remarks/>
        public bool ReceiptsVerified
        {
            get
            {
                return this.receiptsVerifiedField;
            }
            set
            {
                this.receiptsVerifiedField = value;
            }
        }

        /// <remarks/>
        public string ReceiptsVerifiedDate
        {
            get
            {
                return this.receiptsVerifiedDateField;
            }
            set
            {
                this.receiptsVerifiedDateField = value;
            }
        }

        /// <remarks/>
        public string ReceiptsVerifiedbyUser
        {
            get
            {
                return this.receiptsVerifiedbyUserField;
            }
            set
            {
                this.receiptsVerifiedbyUserField = value;
            }
        }

        /// <remarks/>
        public decimal TotalReimbursable
        {
            get
            {
                return this.totalReimbursableField;
            }
            set
            {
                this.totalReimbursableField = value;
            }
        }

        /// <remarks/>
        public decimal TotalNotReimbursable
        {
            get
            {
                return this.totalNotReimbursableField;
            }
            set
            {
                this.totalNotReimbursableField = value;
            }
        }

        /// <remarks/>
        public decimal TotalEmployeeOwes
        {
            get
            {
                return this.totalEmployeeOwesField;
            }
            set
            {
                this.totalEmployeeOwesField = value;
            }
        }

        /// <remarks/>

        public string ExternalID
        {
            get
            {
                return this.externalIDField;
            }
            set
            {
                if (value != null) this.externalIDField = value;                
            }
        }

        /// <remarks/>
        public string CreatedUser
        {
            get
            {
                return this.createdUserField;
            }
            set
            {
                this.createdUserField = value;
            }
        }

        /// <remarks/>
        public System.DateTime CreatedDate
        {
            get
            {
                return this.createdDateField;
            }
            set
            {
                this.createdDateField = value;
            }
        }

        /// <remarks/>
        public string LastEditUser
        {
            get
            {
                return this.lastEditUserField;
            }
            set
            {
                this.lastEditUserField = value;
            }
        }

        /// <remarks/>
        public System.DateTime LastEditDate
        {
            get
            {
                return this.lastEditDateField;
            }
            set
            {
                this.lastEditDateField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("ExpenseDetail")]
        public ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetail[] ExpenseDetail
        {
            get
            {
                return this.expenseDetailField;
            }
            set
            {
                this.expenseDetailField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseRef
    {

        private string guidField;

        private int idField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public int ID
        {
            get
            {
                return this.idField;
            }
            set
            {
                this.idField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseCustomer
    {

        private string guidField;

        private string nameField;

        private string externalIDField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public string Name
        {
            get
            {
                return this.nameField;
            }
            set
            {
                this.nameField = value;
            }
        }

        /// <remarks/>
        public string ExternalID
        {
            get
            {
                return this.externalIDField;
            }
            set
            {
                this.externalIDField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseUser
    {

        private string guidField;

        private string userIDField;

        private string externalIDField;

        private object externalNameField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public string UserID
        {
            get
            {
                return this.userIDField;
            }
            set
            {
                this.userIDField = value;
            }
        }

        /// <remarks/>
        public string ExternalID
        {
            get
            {
                return this.externalIDField;
            }
            set
            {
                this.externalIDField = value;
            }
        }

        /// <remarks/>
        public object ExternalName
        {
            get
            {
                return this.externalNameField;
            }
            set
            {
                this.externalNameField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseApprovedBy
    {

        private string guidField;

        private string userIDField;

        private int externalIDField;

        private object externalNameField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public string UserID
        {
            get
            {
                return this.userIDField;
            }
            set
            {
                this.userIDField = value;
            }
        }

        /// <remarks/>
        public int ExternalID
        {
            get
            {
                return this.externalIDField;
            }
            set
            {
                this.externalIDField = value;
            }
        }

        /// <remarks/>
        public object ExternalName
        {
            get
            {
                return this.externalNameField;
            }
            set
            {
                this.externalNameField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpensePaidBy
    {

        private string guidField;

        private string userIDField;

        private int externalIDField;

        private object externalNameField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public string UserID
        {
            get
            {
                return this.userIDField;
            }
            set
            {
                this.userIDField = value;
            }
        }

        /// <remarks/>
        public int ExternalID
        {
            get
            {
                return this.externalIDField;
            }
            set
            {
                this.externalIDField = value;
            }
        }

        /// <remarks/>
        public object ExternalName
        {
            get
            {
                return this.externalNameField;
            }
            set
            {
                this.externalNameField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseDeniedBy
    {

        private string guidField;

        private string userIDField;

        private int externalIDField;

        private object externalNameField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public string UserID
        {
            get
            {
                return this.userIDField;
            }
            set
            {
                this.userIDField = value;
            }
        }

        /// <remarks/>
        public int ExternalID
        {
            get
            {
                return this.externalIDField;
            }
            set
            {
                this.externalIDField = value;
            }
        }

        /// <remarks/>
        public object ExternalName
        {
            get
            {
                return this.externalNameField;
            }
            set
            {
                this.externalNameField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseCurrency
    {

        private int idField;

        private string codeField;

        /// <remarks/>
        public int ID
        {
            get
            {
                return this.idField;
            }
            set
            {
                this.idField = value;
            }
        }

        /// <remarks/>
        public string Code
        {
            get
            {
                return this.codeField;
            }
            set
            {
                this.codeField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseDepartment
    {

        private uint idField;

        private string departmentField;

        private int gLPrefixField;

        private uint locationIDField;

        private string locationField;

        private int locationGLPrefixField;

        private uint divisionIDField;

        private string divisionField;

        private int divisionGLPrefixField;

        /// <remarks/>
        public uint ID
        {
            get
            {
                return this.idField;
            }
            set
            {
                this.idField = value;
            }
        }

        /// <remarks/>
        public string Department
        {
            get
            {
                return this.departmentField;
            }
            set
            {
                this.departmentField = value;
            }
        }

        /// <remarks/>
        public int GLPrefix
        {
            get
            {
                return this.gLPrefixField;
            }
            set
            {
                this.gLPrefixField = value;
            }
        }

        /// <remarks/>
        public uint LocationID
        {
            get
            {
                return this.locationIDField;
            }
            set
            {
                this.locationIDField = value;
            }
        }

        /// <remarks/>
        public string Location
        {
            get
            {
                return this.locationField;
            }
            set
            {
                this.locationField = value;
            }
        }

        /// <remarks/>
        public int LocationGLPrefix
        {
            get
            {
                return this.locationGLPrefixField;
            }
            set
            {
                this.locationGLPrefixField = value;
            }
        }

        /// <remarks/>
        public uint DivisionID
        {
            get
            {
                return this.divisionIDField;
            }
            set
            {
                this.divisionIDField = value;
            }
        }

        /// <remarks/>
        public string Division
        {
            get
            {
                return this.divisionField;
            }
            set
            {
                this.divisionField = value;
            }
        }

        /// <remarks/>
        public int DivisionGLPrefix
        {
            get
            {
                return this.divisionGLPrefixField;
            }
            set
            {
                this.divisionGLPrefixField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseOrganization
    {

        private uint orgIdField;

        private string orgNameField;

        private int orgTypeIdField;

        private string orgTypeNameField;

        private int orgLevelField;

        private int orgGroupField;

        private int orgRankField;

        private int orgGLPrefixField;

        private string orgExternalIdField;

        /// <remarks/>
        public uint OrgId
        {
            get
            {
                return this.orgIdField;
            }
            set
            {
                this.orgIdField = value;
            }
        }

        /// <remarks/>
        public string OrgName
        {
            get
            {
                return this.orgNameField;
            }
            set
            {
                this.orgNameField = value;
            }
        }

        /// <remarks/>
        public int OrgTypeId
        {
            get
            {
                return this.orgTypeIdField;
            }
            set
            {
                this.orgTypeIdField = value;
            }
        }

        /// <remarks/>
        public string OrgTypeName
        {
            get
            {
                return this.orgTypeNameField;
            }
            set
            {
                this.orgTypeNameField = value;
            }
        }

        /// <remarks/>
        public int OrgLevel
        {
            get
            {
                return this.orgLevelField;
            }
            set
            {
                this.orgLevelField = value;
            }
        }

        /// <remarks/>
        public int OrgGroup
        {
            get
            {
                return this.orgGroupField;
            }
            set
            {
                this.orgGroupField = value;
            }
        }

        /// <remarks/>
        public int OrgRank
        {
            get
            {
                return this.orgRankField;
            }
            set
            {
                this.orgRankField = value;
            }
        }

        /// <remarks/>
        public int OrgGLPrefix
        {
            get
            {
                return this.orgGLPrefixField;
            }
            set
            {
                this.orgGLPrefixField = value;
            }
        }

        /// <remarks/>
        public string OrgExternalId
        {
            get
            {
                return this.orgExternalIdField;
            }
            set
            {
                this.orgExternalIdField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseBatch
    {

        private uint idField;

        private int batchNumberField;

        private string statusField;

        /// <remarks/>
        public uint ID
        {
            get
            {
                return this.idField;
            }
            set
            {
                this.idField = value;
            }
        }

        /// <remarks/>
        public int BatchNumber
        {
            get
            {
                return this.batchNumberField;
            }
            set
            {
                this.batchNumberField = value;
            }
        }

        /// <remarks/>
        public string Status
        {
            get
            {
                return this.statusField;
            }
            set
            {
                this.statusField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetail
    {

        private ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailRef refField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailExpense expenseField;

        private object parentDetailField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailCustomer customerField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailProject projectField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailDepartment departmentField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailOrganization[] organizationsField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailExpenseType expenseTypeField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailPaymentType paymentTypeField;

        private ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailCurrency currencyField;

        private System.DateTime expenseDateField;

        private string descriptionField;

        private object vendorDescriptionField;

        private decimal expenseAmountField;

        private decimal sourceAmountField;

        private decimal conversionRateField;

        private string conversionDateField;

        private decimal customRateField;

        private int reimbursableField;

        private bool hasRequiredDataField;

        private bool isSplitField;

        private bool isParentSplitField;

        private string createdUserField;

        private System.DateTime createdDateField;

        private string lastEditUserField;

        private System.DateTime lastEditDateField;

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailRef Ref
        {
            get
            {
                return this.refField;
            }
            set
            {
                this.refField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailExpense Expense
        {
            get
            {
                return this.expenseField;
            }
            set
            {
                this.expenseField = value;
            }
        }

        /// <remarks/>
        public object ParentDetail
        {
            get
            {
                return this.parentDetailField;
            }
            set
            {
                this.parentDetailField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailCustomer Customer
        {
            get
            {
                return this.customerField;
            }
            set
            {
                this.customerField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailProject Project
        {
            get
            {
                return this.projectField;
            }
            set
            {
                this.projectField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailDepartment Department
        {
            get
            {
                return this.departmentField;
            }
            set
            {
                this.departmentField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlArrayItemAttribute("Organization", IsNullable = false)]
        public ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailOrganization[] Organizations
        {
            get
            {
                return this.organizationsField;
            }
            set
            {
                this.organizationsField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailExpenseType ExpenseType
        {
            get
            {
                return this.expenseTypeField;
            }
            set
            {
                this.expenseTypeField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailPaymentType PaymentType
        {
            get
            {
                return this.paymentTypeField;
            }
            set
            {
                this.paymentTypeField = value;
            }
        }

        /// <remarks/>
        public ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailCurrency Currency
        {
            get
            {
                return this.currencyField;
            }
            set
            {
                this.currencyField = value;
            }
        }

        /// <remarks/>
        public System.DateTime ExpenseDate
        {
            get
            {
                return this.expenseDateField;
            }
            set
            {
                this.expenseDateField = value;
            }
        }

        /// <remarks/>
        public string Description
        {
            get
            {
                return this.descriptionField;
            }
            set
            {
                this.descriptionField = value;
            }
        }

        /// <remarks/>
        public object VendorDescription
        {
            get
            {
                return this.vendorDescriptionField;
            }
            set
            {
                this.vendorDescriptionField = value;
            }
        }

        /// <remarks/>
        public decimal ExpenseAmount
        {
            get
            {
                return this.expenseAmountField;
            }
            set
            {
                this.expenseAmountField = value;
            }
        }

        /// <remarks/>
        public decimal SourceAmount
        {
            get
            {
                return this.sourceAmountField;
            }
            set
            {
                this.sourceAmountField = value;
            }
        }

        /// <remarks/>
        public decimal ConversionRate
        {
            get
            {
                return this.conversionRateField;
            }
            set
            {
                this.conversionRateField = value;
            }
        }

        /// <remarks/>
        public string ConversionDate
        {
            get
            {
                return this.conversionDateField;
            }
            set
            {
                this.conversionDateField = value;
            }
        }

        /// <remarks/>
        public decimal CustomRate
        {
            get
            {
                return this.customRateField;
            }
            set
            {
                this.customRateField = value;
            }
        }

        /// <remarks/>
        public int Reimbursable
        {
            get
            {
                return this.reimbursableField;
            }
            set
            {
                this.reimbursableField = value;
            }
        }

        /// <remarks/>
        public bool HasRequiredData
        {
            get
            {
                return this.hasRequiredDataField;
            }
            set
            {
                this.hasRequiredDataField = value;
            }
        }

        /// <remarks/>
        public bool IsSplit
        {
            get
            {
                return this.isSplitField;
            }
            set
            {
                this.isSplitField = value;
            }
        }

        /// <remarks/>
        public bool IsParentSplit
        {
            get
            {
                return this.isParentSplitField;
            }
            set
            {
                this.isParentSplitField = value;
            }
        }

        /// <remarks/>
        public string CreatedUser
        {
            get
            {
                return this.createdUserField;
            }
            set
            {
                this.createdUserField = value;
            }
        }

        /// <remarks/>
        public System.DateTime CreatedDate
        {
            get
            {
                return this.createdDateField;
            }
            set
            {
                this.createdDateField = value;
            }
        }

        /// <remarks/>
        public string LastEditUser
        {
            get
            {
                return this.lastEditUserField;
            }
            set
            {
                this.lastEditUserField = value;
            }
        }

        /// <remarks/>
        public System.DateTime LastEditDate
        {
            get
            {
                return this.lastEditDateField;
            }
            set
            {
                this.lastEditDateField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailRef
    {

        private string guidField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailExpense
    {

        private string guidField;

        private int idField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public int ID
        {
            get
            {
                return this.idField;
            }
            set
            {
                this.idField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailCustomer
    {

        private string guidField;

        private string nameField;

        private string externalIDField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public string Name
        {
            get
            {
                return this.nameField;
            }
            set
            {
                this.nameField = value;
            }
        }

        /// <remarks/>
        public string ExternalID
        {
            get
            {
                return this.externalIDField;
            }
            set
            {
                this.externalIDField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailProject
    {

        private string guidField;

        private string projectNumberField;

        private object gLSuffixField;

        private string externalIDField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public string ProjectNumber
        {
            get
            {
                return this.projectNumberField;
            }
            set
            {
                this.projectNumberField = value;
            }
        }

        /// <remarks/>
        public object GLSuffix
        {
            get
            {
                return this.gLSuffixField;
            }
            set
            {
                this.gLSuffixField = value;
            }
        }

        /// <remarks/>
        public string ExternalID
        {
            get
            {
                return this.externalIDField;
            }
            set
            {
                this.externalIDField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailDepartment
    {

        private uint idField;

        private string departmentField;

        private int gLPrefixField;

        private uint locationIDField;

        private string locationField;

        private int locationGLPrefixField;

        private uint divisionIDField;

        private string divisionField;

        private int divisionGLPrefixField;

        /// <remarks/>
        public uint ID
        {
            get
            {
                return this.idField;
            }
            set
            {
                this.idField = value;
            }
        }

        /// <remarks/>
        public string Department
        {
            get
            {
                return this.departmentField;
            }
            set
            {
                this.departmentField = value;
            }
        }

        /// <remarks/>
        public int GLPrefix
        {
            get
            {
                return this.gLPrefixField;
            }
            set
            {
                this.gLPrefixField = value;
            }
        }

        /// <remarks/>
        public uint LocationID
        {
            get
            {
                return this.locationIDField;
            }
            set
            {
                this.locationIDField = value;
            }
        }

        /// <remarks/>
        public string Location
        {
            get
            {
                return this.locationField;
            }
            set
            {
                this.locationField = value;
            }
        }

        /// <remarks/>
        public int LocationGLPrefix
        {
            get
            {
                return this.locationGLPrefixField;
            }
            set
            {
                this.locationGLPrefixField = value;
            }
        }

        /// <remarks/>
        public uint DivisionID
        {
            get
            {
                return this.divisionIDField;
            }
            set
            {
                this.divisionIDField = value;
            }
        }

        /// <remarks/>
        public string Division
        {
            get
            {
                return this.divisionField;
            }
            set
            {
                this.divisionField = value;
            }
        }

        /// <remarks/>
        public int DivisionGLPrefix
        {
            get
            {
                return this.divisionGLPrefixField;
            }
            set
            {
                this.divisionGLPrefixField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailOrganization
    {

        private uint orgIdField;

        private string orgNameField;

        private int orgTypeIdField;

        private string orgTypeNameField;

        private int orgLevelField;

        private int orgGroupField;

        private int orgRankField;

        private int orgGLPrefixField;

        private string orgExternalIdField;

        /// <remarks/>
        public uint OrgId
        {
            get
            {
                return this.orgIdField;
            }
            set
            {
                this.orgIdField = value;
            }
        }

        /// <remarks/>
        public string OrgName
        {
            get
            {
                return this.orgNameField;
            }
            set
            {
                this.orgNameField = value;
            }
        }

        /// <remarks/>
        public int OrgTypeId
        {
            get
            {
                return this.orgTypeIdField;
            }
            set
            {
                this.orgTypeIdField = value;
            }
        }

        /// <remarks/>
        public string OrgTypeName
        {
            get
            {
                return this.orgTypeNameField;
            }
            set
            {
                this.orgTypeNameField = value;
            }
        }

        /// <remarks/>
        public int OrgLevel
        {
            get
            {
                return this.orgLevelField;
            }
            set
            {
                this.orgLevelField = value;
            }
        }

        /// <remarks/>
        public int OrgGroup
        {
            get
            {
                return this.orgGroupField;
            }
            set
            {
                this.orgGroupField = value;
            }
        }

        /// <remarks/>
        public int OrgRank
        {
            get
            {
                return this.orgRankField;
            }
            set
            {
                this.orgRankField = value;
            }
        }

        /// <remarks/>
        public int OrgGLPrefix
        {
            get
            {
                return this.orgGLPrefixField;
            }
            set
            {
                this.orgGLPrefixField = value;
            }
        }

        /// <remarks/>
        public string OrgExternalId
        {
            get
            {
                return this.orgExternalIdField;
            }
            set
            {
                this.orgExternalIdField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailExpenseType
    {

        private string guidField;

        private uint idField;

        private string gLCodeField;

        private string gLDescriptionField;

        private string reimbursableField;

        private object externalIDField;

        private decimal defaultAmountField;

        private string lockAmountField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public uint ID
        {
            get
            {
                return this.idField;
            }
            set
            {
                this.idField = value;
            }
        }

        /// <remarks/>
        public string GLCode
        {
            get
            {
                return this.gLCodeField;
            }
            set
            {
                this.gLCodeField = value;
            }
        }

        /// <remarks/>
        public string GLDescription
        {
            get
            {
                return this.gLDescriptionField;
            }
            set
            {
                this.gLDescriptionField = value;
            }
        }

        /// <remarks/>
        public string Reimbursable
        {
            get
            {
                return this.reimbursableField;
            }
            set
            {
                this.reimbursableField = value;
            }
        }

        /// <remarks/>
        public object ExternalID
        {
            get
            {
                return this.externalIDField;
            }
            set
            {
                this.externalIDField = value;
            }
        }

        /// <remarks/>
        public decimal defaultAmount
        {
            get
            {
                return this.defaultAmountField;
            }
            set
            {
                this.defaultAmountField = value;
            }
        }

        /// <remarks/>
        public string lockAmount
        {
            get
            {
                return this.lockAmountField;
            }
            set
            {
                this.lockAmountField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailPaymentType
    {

        private string guidField;

        private int idField;

        private string paymentTypeField;

        private string reimbursableField;

        /// <remarks/>
        public string Guid
        {
            get
            {
                return this.guidField;
            }
            set
            {
                this.guidField = value;
            }
        }

        /// <remarks/>
        public int ID
        {
            get
            {
                return this.idField;
            }
            set
            {
                this.idField = value;
            }
        }

        /// <remarks/>
        public string PaymentType
        {
            get
            {
                return this.paymentTypeField;
            }
            set
            {
                this.paymentTypeField = value;
            }
        }

        /// <remarks/>
        public string Reimbursable
        {
            get
            {
                return this.reimbursableField;
            }
            set
            {
                this.reimbursableField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireSendDataTransactionExpenseSearchExpenseExpenseDetailCurrency
    {

        private int idField;

        private string codeField;

        /// <remarks/>
        public int ID
        {
            get
            {
                return this.idField;
            }
            set
            {
                this.idField = value;
            }
        }

        /// <remarks/>
        public string Code
        {
            get
            {
                return this.codeField;
            }
            set
            {
                this.codeField = value;
            }
        }
    }


    #endregion
}

