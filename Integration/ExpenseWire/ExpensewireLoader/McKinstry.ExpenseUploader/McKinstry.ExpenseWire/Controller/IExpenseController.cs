using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace McKinstry.ExpenseWire.Controller
{
    public interface IExpenseController
    {
        string BatchId { get; set; }
        string Exception { get; set; }
        bool IsFms { get; set; }
        void ProcessExpenses();
        void UpdateExpneseChecks();
    }
}
