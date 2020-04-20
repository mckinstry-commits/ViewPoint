using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using McKinstry.ExpenseWire.Controller;

namespace McKinstry.ExpenseWire.Controller
{
    public class ExpenseControllerFactory 
    {
        public string BatchId { get; set; }
        public string Exception { get; set; }
        public bool IsFms { get; set; }
        IExpenseController iExpenseController;
        public ExpenseControllerFactory(IExpenseController iEC)
        {
            iExpenseController = iEC;
        }

        public void LoadExpenses()
        {
            iExpenseController.BatchId = BatchId;
            Exception = null;
            iExpenseController.IsFms = IsFms;
            iExpenseController.ProcessExpenses();
            this.Exception = iExpenseController.Exception;
        }

        public void UpdateCheckNumber()
        {
            iExpenseController.BatchId = BatchId;
            iExpenseController.IsFms = IsFms;
            iExpenseController.UpdateExpneseChecks();
        }
      
    }
}
