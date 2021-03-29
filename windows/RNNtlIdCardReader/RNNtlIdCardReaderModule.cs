using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace Ntl.Id.Card.Reader.RNNtlIdCardReader
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNNtlIdCardReaderModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNNtlIdCardReaderModule"/>.
        /// </summary>
        internal RNNtlIdCardReaderModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNNtlIdCardReader";
            }
        }
    }
}
