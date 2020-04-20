

namespace McK.Data.Viewpoint
{
    public class Company
    {
        private byte _co;
        private string _name;
        public byte Co { get; set; }
        public string Name { get; set; }
        public Company() { }
        public Company(byte co, string name)
        {
            _co = co;
            _name = name;
        }
    }
}
