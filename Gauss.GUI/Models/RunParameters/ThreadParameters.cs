namespace Gauss.GUI.Models.RunParameters
{
    public class ThreadParameters
    {
        public int ThreadNumber { get; set; }
        public GeneratorParameters GeneratorParameters { get; set; }
        public Size<int> ImageSizes { get; set; }
    }
}