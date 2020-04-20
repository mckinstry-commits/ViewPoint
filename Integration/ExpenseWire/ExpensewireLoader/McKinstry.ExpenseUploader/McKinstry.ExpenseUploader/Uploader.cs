using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using System.Xml;
using System.Xml.Serialization;
using System.Xml.Schema;
using System.Xml.Linq;
using System.Xml.XPath;
using System.IO;

using System.Configuration;
using System.Text.RegularExpressions;

using McKinstry.ExpenseWire;
using McKinstry.ExpenseWire.Controller;

namespace McKinstry.ExpenseUploader
{
    public partial class Uploader : Form
    {
        ExpenseControllerFactory factory = null;
        public Uploader()
        {
            InitializeComponent();          
        }
        private void bUpload_Click(object sender, EventArgs e)
        {
            if (factory == null)
                factory = new  ExpenseControllerFactory(new ExpenseController());

            if(tbBatch.Text != "")
            {
                richTB.Clear();
                richTB.AppendText("Batch " + tbBatch.Text + " started at " + DateTime.Now.ToLongTimeString() + ". \r\n");
                factory.BatchId = tbBatch.Text;
                factory.IsFms = cbFMS.Checked;
                factory.LoadExpenses();
                if (factory.Exception != null)
                {
                    richTB.AppendText(factory.Exception);
                    //File.WriteAllText(@"c:\ExpensewireLog.txt", factory.Exception);
                }
                else
                {
                    richTB.AppendText("Batch " + tbBatch.Text + " completed at " + DateTime.Now.ToLongTimeString() + ". \r\n");
                }
            }
        }


        private void bUpdateChecks_Click(object sender, EventArgs e)
        {
            if(factory ==null)
                factory = new ExpenseControllerFactory(new ExpenseController());

            if (tbBatch.Text != "")
            {
                factory.BatchId = tbBatch.Text;
                factory.IsFms = cbFMS.Checked;
                richTB.AppendText("Check number update for batch " + tbBatch.Text + " started at " + DateTime.Now.ToLongTimeString() + ". \r\n");
                factory.UpdateCheckNumber();
               // factory.
                if (factory.Exception != null)
                {
                    richTB.AppendText(factory.Exception);
                }
                else
                {
                    richTB.AppendText("Check number update for batch " + tbBatch.Text + " completed at " + DateTime.Now.ToLongTimeString() + ". \r\n");
                }
            }

        }

     
    }
}
