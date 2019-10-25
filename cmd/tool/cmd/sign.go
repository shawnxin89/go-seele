/**
*  @file
*  @copyright defined in go-seele/LICENSE
 */

 package cmd

 import (
	 "fmt"
	 "encoding/json"
	 "encoding/hex"

	 "github.com/seeleteam/go-seele/common/hexutil"
	 "github.com/seeleteam/go-seele/crypto"
	 "github.com/seeleteam/go-seele/core/types"
	 "github.com/spf13/cobra"
 )
 
 var (
	privateKey *string
	message string
 )
 
 // signCmd represents the sign command
 var signCmd = &cobra.Command{
	 Use:   "sign",
	 Short: "sign a message",
	 Long: `For example:
			 tool.exe sign`,
	 Run: func(cmd *cobra.Command, args []string) {
		key, err := crypto.LoadECDSAFromString(*privateKey)
		if err != nil {
			fmt.Printf("failed to load the private key: %s\n", err.Error())
			return
		}
		 
		messageBytes := []byte(nil)
		if len(message) > 0 {
			if messageBytes, err = hexutil.HexToBytes(message); err != nil {
				fmt.Errorf("invalid message, %s", err)
			}
		}

		//messageHash := crypto.MustHash(messageBytes)
		messageHash := crypto.Keccak256Hash(messageBytes)
		signature := *crypto.MustSign(key, messageHash.Bytes())
		var tx = types.Transaction{}
		tx.Signature = signature

		result, _ := json.MarshalIndent(tx, "", "\t")

		fmt.Println(string(result))
		fmt.Println("message")
		fmt.Println(hex.EncodeToString(messageBytes))
		fmt.Println("message hash")
		fmt.Println(hex.EncodeToString(messageHash.Bytes()))
		fmt.Println("signature")
		fmt.Println(hex.EncodeToString(signature.Sig))
	 },
 }
 
 func init() {
	 rootCmd.AddCommand(signCmd)
 
	 privateKey = signCmd.Flags().StringP("key", "k", "", "private key")
	 signCmd.Flags().StringVarP(&message, "message", "m", "", "message to sign")
 }
 