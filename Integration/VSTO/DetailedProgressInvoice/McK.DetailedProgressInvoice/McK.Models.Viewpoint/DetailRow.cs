using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.JBDetailedProgressInvoice.Viewpoint
{
    public class DetailRow
    {
        public string InvoiceJBIN { get; set; }
        public string ItemJCCI { get; set; }
        public string DescriptionJBIS { get; set; }
        public decimal CurrContractAmt { get; set; }
        public decimal CurrContract { get; set; }
        public decimal ChgOrderAmt { get; set; }
        public decimal BalanceToFinish { get; set; }
        public decimal PrevAmt { get; set; }
        public decimal PrevAmtJBIN { get; set; }
        public decimal AmtBilled { get; set; }
        public decimal CurrRetention { get; set; }
        public decimal JTDRetention { get; set; }
        public decimal StoredMaterials { get; set; }
        public decimal TotalComplToDate { get; set; }
        public decimal PerctCompleted { get; set; }
        public decimal InvTotal { get; set; }
        public decimal PrevRetgJBIN { get; set; }
        public decimal PrevRRel { get; set; }
        public decimal InvRetg { get; set; }
        public decimal RetgRelJBIN { get; set; }
        public decimal PrevRetgTaxJBIN { get; set; }
        public decimal PrevRetgTaxRelJBIN { get; set; }
        public decimal RetgTaxJBIN { get; set; }
        public decimal RetgTaxRelJBIN { get; set; }
        public decimal RetgRelJBIS { get; set; }
        public decimal PrevDue { get; set; }
        public decimal InvDue { get; set; }
        public decimal InvTax { get; set; }
        public decimal PrevTax { get; set; }
        public decimal TaxAmtJBIT { get; set; }
        public string Notes { get; set; }
        //public override bool Equals(object obj)
        //{
        //    var other = obj as DetailRow;
        //    return other != null && other.InvoiceJBIN == this.InvoiceJBIN;
        //}
        //public override int GetHashCode() => InvoiceJBIN.GetHashCode();
    }
}
