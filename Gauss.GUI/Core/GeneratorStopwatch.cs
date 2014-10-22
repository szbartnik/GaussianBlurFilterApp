using System;
using System.Timers;

namespace Gauss.GUI.Core
{
    public class GeneratorStopwatch
    {
        public delegate void UpdatedEventHandler(TimeSpan updatedTime);
        public event UpdatedEventHandler Updated;

        private readonly Timer _computationTimeTimer;
        private DateTime _computationStartTime;

        public GeneratorStopwatch(TimeSpan refreshInterval)
        {
            _computationTimeTimer = new Timer(refreshInterval.TotalSeconds);
            _computationTimeTimer.Elapsed += (o, e) =>
            {
                if (Updated == null) return;
                Updated(DateTime.Now - _computationStartTime);
            };
        }

        public void Start()
        {
            _computationStartTime = DateTime.Now;
            _computationTimeTimer.Start();
        }

        public void Stop()
        {
            _computationTimeTimer.Stop();
        }
    }
}
