namespace McKinstry.ViewPoint.Subcontract
{
    partial class SubcontractTaskPanel
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.tbSL = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.bGenerate = new System.Windows.Forms.Button();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.cbCompany = new System.Windows.Forms.ComboBox();
            this.label2 = new System.Windows.Forms.Label();
            this.lCO = new System.Windows.Forms.Label();
            this.tbCO = new System.Windows.Forms.TextBox();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.SuspendLayout();
            // 
            // tbSL
            // 
            this.tbSL.Location = new System.Drawing.Point(112, 121);
            this.tbSL.Name = "tbSL";
            this.tbSL.Size = new System.Drawing.Size(190, 20);
            this.tbSL.TabIndex = 1;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.BackColor = System.Drawing.Color.AliceBlue;
            this.label1.CausesValidation = false;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.ForeColor = System.Drawing.SystemColors.Desktop;
            this.label1.Location = new System.Drawing.Point(-4, 122);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(110, 16);
            this.label1.TabIndex = 2;
            this.label1.Text = "Subcontract # :";
            // 
            // bGenerate
            // 
            this.bGenerate.BackColor = System.Drawing.Color.LightGray;
            this.bGenerate.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.bGenerate.Location = new System.Drawing.Point(112, 249);
            this.bGenerate.Name = "bGenerate";
            this.bGenerate.Size = new System.Drawing.Size(190, 61);
            this.bGenerate.TabIndex = 3;
            this.bGenerate.Text = "Generate Contract";
            this.bGenerate.UseVisualStyleBackColor = false;
            this.bGenerate.Click += new System.EventHandler(this.bGenerate_Click);
            // 
            // pictureBox1
            // 
            this.pictureBox1.Image = global::McKinstry.ViewPoint.Subcontract.Properties.Resources.McKLogo;
            this.pictureBox1.Location = new System.Drawing.Point(6, 4);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(296, 92);
            this.pictureBox1.TabIndex = 4;
            this.pictureBox1.TabStop = false;
            // 
            // cbCompany
            // 
            this.cbCompany.DisplayMember = "Text";
            this.cbCompany.FormattingEnabled = true;
            this.cbCompany.Location = new System.Drawing.Point(112, 147);
            this.cbCompany.Name = "cbCompany";
            this.cbCompany.Size = new System.Drawing.Size(190, 21);
            this.cbCompany.TabIndex = 5;
            this.cbCompany.ValueMember = "Value";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Bold);
            this.label2.ForeColor = System.Drawing.SystemColors.Desktop;
            this.label2.Location = new System.Drawing.Point(-4, 155);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(81, 16);
            this.label2.TabIndex = 6;
            this.label2.Text = "Company :";
            // 
            // lCO
            // 
            this.lCO.AutoSize = true;
            this.lCO.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Bold);
            this.lCO.ForeColor = System.Drawing.SystemColors.Desktop;
            this.lCO.Location = new System.Drawing.Point(0, 191);
            this.lCO.Name = "lCO";
            this.lCO.Size = new System.Drawing.Size(29, 16);
            this.lCO.TabIndex = 7;
            this.lCO.Text = "CO";
            // 
            // tbCO
            // 
            this.tbCO.Location = new System.Drawing.Point(112, 191);
            this.tbCO.Name = "tbCO";
            this.tbCO.Size = new System.Drawing.Size(190, 20);
            this.tbCO.TabIndex = 8;
            // 
            // SubcontractTaskPanel
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.AliceBlue;
            this.Controls.Add(this.tbCO);
            this.Controls.Add(this.lCO);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.cbCompany);
            this.Controls.Add(this.pictureBox1);
            this.Controls.Add(this.bGenerate);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.tbSL);
            this.Name = "SubcontractTaskPanel";
            this.Size = new System.Drawing.Size(308, 363);
            this.Load += new System.EventHandler(this.SubcontractTaskPanel_Load);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox tbSL;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Button bGenerate;
        private System.Windows.Forms.PictureBox pictureBox1;
        private System.Windows.Forms.ComboBox cbCompany;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label lCO;
        private System.Windows.Forms.TextBox tbCO;
    }
}
