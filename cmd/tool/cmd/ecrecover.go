/**
*  @file
*  @copyright defined in go-seele/LICENSE
 */

 package cmd

 import (
	 "fmt"
	 "encoding/hex"

	 "github.com/seeleteam/go-seele/common"
	 "github.com/seeleteam/go-seele/common/hexutil"
	 "github.com/seeleteam/go-seele/crypto"
	 "github.com/spf13/cobra"
 )
 
 var (
	signerAddress string
	signature     string
 )
 
 // signCmd represents the sign command
 var verifyCmd = &cobra.Command{
	 Use:   "verify",
	 Short: "verify a signature",
	 Long: `For example:
			 tool.exe verify`,
	 Run: func(cmd *cobra.Command, args []string) {
		 
		messageBytes := []byte(nil)
		if len(message) > 0 {
			messageBytes, _ = hexutil.HexToBytes(message)
		}

		//messageHash := crypto.MustHash(messageBytes)
		messageHash := crypto.Keccak256Hash(messageBytes)
		address, _ := common.HexToAddress(signerAddress)
		decodedString, _ := hex.DecodeString(signature)
		sig := &crypto.Signature{Sig: decodedString}
		isValid := sig.Verify(address, messageHash.Bytes())
		if isValid {
			fmt.Println("True")
		} else {
			fmt.Println("False")
		}
	 },
 }
 
 func init() {
	 rootCmd.AddCommand(verifyCmd)
 
	 verifyCmd.Flags().StringVarP(&signerAddress, "address", "a", "", "signer address")
	 verifyCmd.Flags().StringVarP(&signature, "signature", "g", "", "signature of the message")
	 verifyCmd.Flags().StringVarP(&message, "message", "m", "", "signed message")
 }

 //(s Signature) Verify(signer common.Address, hash []byte) bool