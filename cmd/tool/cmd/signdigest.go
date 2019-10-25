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
	messageDigest string
 )
 
 // signCmd represents the sign command
 var signdigestCmd = &cobra.Command{
	 Use:   "signdigest",
	 Short: "sign a message digest",
	 Long: `For example:
			 tool.exe signdigest`,
	 Run: func(cmd *cobra.Command, args []string) {
		key, err := crypto.LoadECDSAFromString(*privateKey)
		if err != nil {
			fmt.Printf("failed to load the private key: %s\n", err.Error())
			return
		}
		 
		messageDigestBytes := []byte(nil)
		if len(messageDigest) > 0 {
			if messageDigestBytes, err = hexutil.HexToBytes(messageDigest); err != nil {
				fmt.Errorf("invalid message, %s", err)
			}
		}

		signature := *crypto.MustSign(key, messageDigestBytes)
		var tx = types.Transaction{}
		tx.Signature = signature

		result, _ := json.MarshalIndent(tx, "", "\t")

		fmt.Println(string(result))
		fmt.Println("message hash")
		fmt.Println(hex.EncodeToString(messageDigestBytes))
		fmt.Println("signature")
		fmt.Println(hex.EncodeToString(signature.Sig))
	 },
 }
 
 func init() {
	 rootCmd.AddCommand(signdigestCmd)
 
	 privateKey = signdigestCmd.Flags().StringP("key", "k", "", "private key")
	 signdigestCmd.Flags().StringVarP(&messageDigest, "digest", "d", "", "message digest to sign")
 }