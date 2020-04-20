using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace McKinstry.ExpenseWire.Model
{
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    [System.Xml.Serialization.XmlRootAttribute(ElementName="ExpenseWire", Namespace = "", IsNullable = false)]
    public partial class ExpenseWireSend
    {
        private DataTransaction dataTransactionField;
        /// <remarks/>
        public DataTransaction DataTransaction
        {
            get
            {
                return this.dataTransactionField;
            }
            set
            {
                this.dataTransactionField = value;
            }
        }
    }
    #region "Search ExpebseWire"
    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    [System.Xml.Serialization.XmlRootAttribute(IsNullable = true)]
    public partial class DataTransaction
    {

        private object customerField;

        private object projectField;


        private Expense expenseField1;

        /// <remarks/>
        public object Customer
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
        [System.Xml.Serialization.XmlElement("Expense")]
        public Expense Expense
        {
            get
            {
                return this.expenseField1;
            }
            set
            {
                this.expenseField1 = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class Expense
    {

        private Search searchField;

        /// <remarks/>
        public Search Search
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
    public partial class Search
    {

        private ExpenseWireDataTransactionExpenseSearchBatch batchField;

        private string approvalDepthField;

        private string detailLevelField;

        private int maxRowsField;

        /// <remarks/>
        public ExpenseWireDataTransactionExpenseSearchBatch Batch
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
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string ApprovalDepth
        {
            get
            {
                return this.approvalDepthField;
            }
            set
            {
                this.approvalDepthField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string DetailLevel
        {
            get
            {
                return this.detailLevelField;
            }
            set
            {
                this.detailLevelField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public int MaxRows
        {
            get
            {
                return this.maxRowsField;
            }
            set
            {
                this.maxRowsField = value;
            }
        }
    }

    /// <remarks/>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true)]
    public partial class ExpenseWireDataTransactionExpenseSearchBatch
    {

        private object batchNumberField;

        /// <remarks/>
        public object BatchNumber
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
    }
    #endregion
}
