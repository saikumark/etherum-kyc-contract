pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

/**
@title KYC Contract
 */
contract KYCContract{
    
    /**
	@notice Customer structure to store details of customer
	 */
    struct Customer{
        string userName; 		// Provided by the customer and used as unique identifier 
        string password; 		// Password to Protect the customer data from external views
        string customerData; 	// Hash of the data or identity documents provided by the customer
        uint256 rating;			// Rating given to the customer based on the regularity by other banks
        uint32 upVotes; 		// Number of votes received from other banks over the Customer data
        address bank; 			//This is a unique address of the bank that validated the customer account
    }
    
    /**
	@notice Bank structure to store details of the bank
	 */
    struct Bank{
        string name; 			// Name of the bank/organisation
        address ethAddress; 	// Unique Ethereum address of the bank/organisation
        uint32 rating; 			// Rating received from other banks based on number of valid/invalid KYC verifications
        uint32 kycCount; 		// Number of KYC requests initiated by the bank/organisation
        string regNumber; 		// Unique registration number for the bank
    }
    
	/**
	@notice KycRequest structure to contain KYC request from bank initiated for a customer. 
	 */
    struct KycRequest{
		string uname; 			// Map the KYC request with the unique user name.
		address bankAddress; 	// Bank address here is a unique account address for the bank, which can be used to track the bank.
		string customerData; 	// Hash of customer data or identification documents provided by the Customer. This is unique for each request.
		bool isAllowed; 		// IsAllowed is used to specify if the request is added by a trusted bank or not. It is set to false for all the bank requests done by the bank if bank is not secure.
	}
	
	/**
	@notice BankRating structure to contain rating given by a bank to other bank
	 */
	struct BankRating{
	    address fromBankAddress; //Bank which provides rating 
	    address toBankAddress; //Bank which was rated
	}
	
	/**
	@notice CustomerRating structure to contain rating given by Bank to a customer
	 */
	struct CustomerRating{
	    address fromBankAddress; //Bank which provides rating to customer
	    string toCustomerName; //customer who was rated
	}
	
	/**
	@notice Contains address of the contract owner
	 */
	address contractOwner; 

	/**
	@notice  Contains list of customer for which KYC request was submitted
	 */
    Customer[] public customerList;
    
	/**
	@notice final list of customers for which KYC requests were approved with higher rating
	 */
    Customer[] public finalCustomerList;
    
	/**
	@notice List of banks added by Admin and it's details
	 */
    Bank[] public bankList;
    
	/**
	@notice Contains all KYC requests raised by different set of banks
	 */
    KycRequest[] public requestList;
    
	/**
	@notice Contains list of rating request by Bank to other banks
	 */
    BankRating[] public voteBankList;
    
	/**
	@notice Contains list of rating request by Bank to customers
	 */
    CustomerRating[] public customerRatingList;
    
	/**
	@notice To retrieve list of KYC requests by a specific bank based on address
	 */
    mapping(address => string[]) public bankRequestList;
    
	/**
	@notice To fetch access log for customer data 
	 */
    mapping(string => address) accessHistory;
    
	/**
	@notice public constructor for KYCContract
	*/
    constructor() public {
        contractOwner = msg.sender; //Contains owner of the contract 
    }
    
	/**
	@notice To compare two strings and return true or false. 
	@param a : String 
	@param b : String
	@return boolean
	 */
	function hashCompareWithLengthCheck(string memory a, string memory b) internal pure returns (bool) {

		if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))) {
			return true;
		}
		else {
			return false;
		}
	}
    
    /**
	@notice Used Create new KYC request by Bank if the request for specific customer is not already in list of KYC requests.
	@param customerName : String
	@param customerData : String
	@return Boolean, 0 if KYC request for customer already present in the storage, otherwise return 1.
	 */
    function addRequest ( string memory customerName, string memory customerData ) public payable returns( uint ) {
        
        /* Checking if the request with same customerName & customerData already created.
           If already created then reject the request by returning 0.
        */
        
        for ( uint i = 0; i < requestList.length; ++i ) {
			if ( hashCompareWithLengthCheck(requestList[i].uname, customerName) && 
			        hashCompareWithLengthCheck(requestList[i].customerData,customerData) ) {
					return 0;
			}
		}
		
		//Contains whether the bank is allowed for validation based on it's rating
		bool isBankAllowedValidation = false;
		
		//Increase the kycCount field for request raised by the bank
		for ( uint i = 0; i < bankList.length; i++ ) {
	        if ( bankList[i].ethAddress == msg.sender ) {
	            bankList[i].kycCount++;
	            // if ( bankList[i].rating > uint256(0.5)){ //if Bank's rating is greater than 0.5 then it is allowed to validate KYC
				//Couldn't execute above logic as I got an error Error: CompileError: UnimplementedFeatureError: Not yet implemented - FixedPointType. and couldn't proceed further
				if ( (bankList.length - bankList[i].rating ) <= bankList[i].rating ){
	            	isBankAllowedValidation = true;
				}
				break;
	        }
		}
		
		// Increase the length of the requestList to store the new request
		requestList.length++; 
		requestList[requestList.length - 1] = KycRequest(customerName,msg.sender,customerData,isBankAllowedValidation);
		
		//returning 1 as successfull request creation
		return 1;
    }
    
	/**
	@notice Add given customer details to KYC list
	@param customerName string
	@param customerData string
	@return UNIT 1 if customer is added successfull else returns 0
	 */
    function addCustomer ( string memory customerName, string memory customerData ) public payable returns( uint ) {
        
        /**
		@dev If customerName is not present already in the list of customer list, then proceed
        */
        for ( uint i = 0; i < customerList.length; ++i ) {
			if ( hashCompareWithLengthCheck(customerList[i].userName, customerName) )
			return 0;
        }
		
		/**
		@dev check if the kyc request is created for this customer or not in requestList and isAllowed is true then add the customer to customerList
		*/
		for ( uint i = 0; i < requestList.length; i++ ) {
		    
		    //checking if the request is created for customer or not
		    if(hashCompareWithLengthCheck(requestList[i].uname,customerName) && hashCompareWithLengthCheck(requestList[i].customerData,customerData) && requestList[i].isAllowed == true){

				//Increasing the length of the customerList to add new customer data
				customerList.length++;
				
				//Adding the new customer to the list
				customerList[customerList.length-1] = Customer(customerName, "0", customerData,0,0,msg.sender);
				
				//Once customer is added successfully to the list we can remove it from the kycRequest list
				removeRequest(customerName,customerData);
				
				//Save the accessHistory of customer details
				accessHistory[customerName] = msg.sender;
				
				//returning 1 as customer is added successfully
				return 1;
		                
		    }
		}
		//returning 0 , customer details are not added to the list
		return 0;
    }


	/**
	@notice To remove requested customer information from KYC
	@dev scope public
	@param customerName string
	@param customerData string
	@return UNIT returns 1 if request is deleted successfully else returns 0
	 */
    function removeRequest ( string memory customerName, string memory customerData ) public payable returns( uint ) {
        
        /* check if the customer details present in the requestList
           if present then remove it from the list by shifting the next reques to its position
           and rest of the requests to one position left
        */
		for ( uint i = 0; i < requestList.length; ++i ) {
		    
		    //comparison of given data with existing list data
			if ( hashCompareWithLengthCheck(requestList[i].uname, customerName) && hashCompareWithLengthCheck(requestList[i].customerData,customerData) ) {
				
				if ( requestList.length >= 2 && i != (requestList.length-1)) {
				    
				    //shifting of requests
				    for (uint j = i+1; j < requestList.length; ++j ) {
				        requestList[j-1] = requestList[j];
				    }
				}
				
				//decreasing the length of the list by 1 
				requestList.length --;
				//returning 1 as successfull removal of request
				return 1;
			}
		}
		// returning 0 as request couldnt find in the list
		return 0;
	}
	
	/**
	@notice Remove customer from customer list
	@param customerName : String
	@return UNIT returns 1 if given customer name present in the customer list and removed, otherwise return 0 
	 */
	function removeCustomer ( string memory customerName ) public payable returns( uint ) {
	    
	   /* check if the customer details present in the requestList
          if present then remove it from the list by shifting the next reques to its position
          and rest of the requests to one position left
        */
		for ( uint i = 0; i < customerList.length; ++i ) {
		    
		    //comparison of given data with existing list data
			if ( hashCompareWithLengthCheck(customerList[i].userName, customerName) ) {
			    
			    if ( customerList.length >= 2 && i != customerList.length-1) { 
			        
			        //shifting of customers
			        for ( uint j = i+1; j < customerList.length; ++j ) {
			            customerList[j-1] = customerList[j];
			        }
			    }
				
				//decreasing the length of the list by 1
				customerList.length --;
				//returning 1 as successfull removal of request
				return 1;
			}
		}
		// returning 0 as request couldnt find in the list
		return 0;
	}
	
	/**
	@notice To Retrieve and view customer data
	@param customerName : String 
	@param password : String
	@return 
	 */
	//function is used to view the customer details
	//@params customerName as string
	//@params password as string
	//@returns the customer details if found else print the meesage that customer is not found
	
	function viewCustomer ( string memory customerName, string memory password ) public view returns( string memory ) {
		
		//if the password is empty, then assign to 0
		if(abi.encodePacked(password).length  == 0) {
			password = "0";
		}

		//If customer data present return
		for ( uint i = 0; i < customerList.length; ++i ) {
			if ( hashCompareWithLengthCheck(customerList[i].userName, customerName) && hashCompareWithLengthCheck(customerList[i].password,password) ) {
	            return customerList[i].customerData; // returning the customer data
			}
		}
		//returning message as customer details are not found
		return "Invalid credentials or customer not present in database!";
	}
	
	/**
	@notice Cast a vote to customer by Bank if not already voted
	@param customerName : String
	@return UNIT returns 1 if the cast of a vote to customer is successful, otherwise 0
	 */
	function upVoteCustomer ( string memory customerName ) public payable returns( uint ) {
		
		/**
		@dev If the bank is not already voted, proceed to next step. 
	    */
	    for ( uint i = 0; i < customerRatingList.length; ++i ) {
	        if ( customerRatingList[i].fromBankAddress == msg.sender && hashCompareWithLengthCheck(customerRatingList[i].toCustomerName,customerName) ) {
	            return 0;
	        }
	    }
	    
		//checking for the customer in customerList
		for ( uint i = 0; i < customerList.length; ++i ) {
			
			if ( hashCompareWithLengthCheck(customerList[i].userName, customerName) ) {
			    
			    //customer found in the list so increase vote by 1
			    customerList[i].upVotes++;
			    
			    //calculate the rating for the customer
			    customerList[i].rating = customerList[i].upVotes;
			    
			    bool addToFinalCustomer = false;
			    
			    // if( bankList.length > 0 && ( customerList[i].rating - bankList.length ) > uint256(0.5) )
				//Couldn't execute above logic as I got an error Error: CompileError: UnimplementedFeatureError: Not yet implemented - FixedPointType. and couldn't proceed further
				if ( (bankList.length - bankList[i].rating ) <= bankList[i].rating )
			        addToFinalCustomer = true;
			    
			    //if rating percentage is more than 50% then add the customer to finalCustomerList
			    if ( addToFinalCustomer ) {
			        
			        //increasing the length of the finalCustomerList to add the customer
			        finalCustomerList.length++;
			        
			        //adding the customer to finalCustomerList
			        finalCustomerList[finalCustomerList.length-1] = customerList[i];
			    }
			    
			     //we want to track the from & to rated customer , increase the length of the list by one for new entry
	            customerRatingList.length++;
	            
	            //save the bank which rates the other customer
	            customerRatingList[customerRatingList.length-1].fromBankAddress = msg.sender;
	            
	            //save the rated customer  
	            customerRatingList[customerRatingList.length-1].toCustomerName = customerName;
			    
			    //storing the accessHistory details
			    accessHistory[customerName] = msg.sender;
			    
			    //returning 1 as upvoted successfully
			    return 1;
				}
		}
		//returning 0, couldnt find the customer
		return 0;
	}
	
	/**
	@notice Modify customer data for the given credentials. 
	@param customerName : String - For which the new customer data to be replaced
	@param password : String - password of the customer
	@param newCustomerData : String - New customer data to bre placed
	@return UNIT - returns 1 if customer modification is success, otherwise 0
	 */
	function modifyCustomer ( string memory customerName, string memory password, string memory newCustomerData ) public payable returns( uint ) {
	    
		//if the password is empty, then assign to 0
		if(abi.encodePacked(password).length  == 0) {
			password = "0";
		}

	    //checking if the customer is found customerList
	    for ( uint i = 0; i < customerList.length; i++ ) {
	        
			if ( hashCompareWithLengthCheck(customerList[i].userName, customerName) &&  hashCompareWithLengthCheck(customerList[i].password,password) ) {
			            
				//change the customerData to new dataHash
				customerList[i].customerData = newCustomerData;

				//resetting the upVotes & rating to 0
				customerList[i].upVotes = 0;
				customerList[i].rating = 0;
			    
			    /**
				@dev Since customer dataHash got changed removing the customer details from finalCustomerList
			    */

			    for ( uint j = 0; j < finalCustomerList.length;j++ ) {
			        if ( hashCompareWithLengthCheck(finalCustomerList[j].userName,customerName) ) {
						//removeElement(finalCustomerList, j);
						require(j < finalCustomerList.length);
                		finalCustomerList[j] = finalCustomerList[finalCustomerList.length-1];
                		delete finalCustomerList[finalCustomerList.length-1];
                		finalCustomerList.length--;		

						return 1;
					}
			    }
			}
	    }
			
        //returning 0 , couldnt find the customer
        return 0;
	}

	/**
	@notice Remove an Element from Array and move last element of an array to deleted index
	@param array : Array of Struct or UNIT
	@param index : UNIT
	 */
// 	function removeElement(struct [] memory array, uint index) private {
// 		require(index < array.length);
// 		array[index] = array[array.length-1];
// 		delete array[array.length-1];
// 		array.length--;		
// 	}
	
	/**
	@notice Retrieve list of all KYC requests by given bank
	@param bankAddress : Address of bank
	@return Array of KYC requests by a bank which are not validated yet.
	 */
	function getBankRequests ( address bankAddress ) public payable returns( string[] memory ) {
	   
		if(bankRequestList[bankAddress].length!=0){
			delete bankRequestList[bankAddress];
		}
		
	   	for ( uint i = 0; i < requestList.length; ++i ) {
			if ( requestList[i].bankAddress == bankAddress ) {
		        //store the request details to list
				bankRequestList[bankAddress].push(requestList[i].uname);
			}
		}
		
		return bankRequestList[bankAddress];
	    
	}
	
	/**
	@notice Vote another bank if not already by the source bank to target bank
	@param bankAddress : Bank address for which the voting to be given
	@return UNIT - Returns 1 if upvote is success
	 */
	function upVoteBank ( address bankAddress ) public payable returns( uint ) {
	    
	    /*checking if the bank is rated the other bank already
	      if rated then reject the request by returning 1
	    */ 
	    for ( uint i = 0; i < voteBankList.length; i++ ) {
	        if ( voteBankList[i].fromBankAddress == msg.sender && voteBankList[i].toBankAddress == bankAddress ) {
	            return 1;
	        }
	    }
	    
	    //check if the bank exists in the current bankList
	    for ( uint i = 0; i < bankList.length; i++ ) {
	        
	        if ( bankList[i].ethAddress == bankAddress ) {
	            
	            //bank exists in the list increase the rating by 1
	            bankList[i].rating++;
	            
	            //we want to track the from & to rated banks , increase the length of the list by one for new entry
	            voteBankList.length++;
	            
	            //save the bank which rates the other bank
	            voteBankList[voteBankList.length-1].fromBankAddress = msg.sender;
	            
	            //save the rated bank  
	            voteBankList[voteBankList.length-1].toBankAddress = bankAddress;
	            
	            //return 0 for successfull of rateOtherBank
	            return 0;
	        }
	    }
	    //return 1 if the bank is not found in the list 
	    return 1;
	}
	
	/**
	@notice Get rating for given customer
	@param username - String 
	@return UINT
	 */
    function getCustomerRating ( string memory username ) public payable returns( uint ) {
        
        //checking if the customerName exists in the customerList
        for ( uint i = 0; i < customerList.length; ++ i ) {
            if ( hashCompareWithLengthCheck(customerList[i].userName, username) ) {
                
                //since customer exists in the list returning the up
                return customerList[i].rating;
            }
        }
        
        //returns 0 if customer is not found in the list
        return 0;
    }
    
	/**
	@notice Get rating for given bank
	@param bankAddress - address 
	@return UINT
	 */
    function getBankRating ( address bankAddress ) public payable returns( uint ) {
        
        //checking if the bank exists in the list
        for ( uint i = 0; i < bankList.length; ++i ) {
            
            if ( bankList[i].ethAddress == bankAddress ) {
                
                //since bank exists in the list, returning the rating
                return bankList[i].rating;
            }
        }
        
        //returning 0 , bank is not found the list
        return 0;
    }
	
	/**
	@notice Retrieve customer access logs for given username
	@param username : String
	@return Address
	 */
	function retrieveCustomerAccessHistory ( string memory username ) public payable returns( address ) {
		if(accessHistory[username]!=address(0)) {
			return accessHistory[username];
		}
		else{
			return address(0);
		}
    }
	
	/**
	@notice Set password for the given user
	@param username : String
	@param password : String
	@return Boolean 
	 */
	function setPassword (string memory username, string memory password ) public payable returns( bool ) {
	   
	    //checking for the customer in the list
	    for ( uint i = 0; i < customerList.length; ++i ) {
	        
			if ( hashCompareWithLengthCheck(customerList[i].userName, username) && abi.encodePacked(password).length > 0 ) {
			    
			    //customer is found in the list setting the password for customer
			    customerList[i].password = password;
			    
			    //store the address of the bank which modified the customer
			    accessHistory[username] = msg.sender;
			    
			    //returning true after successfully setting the password
			    return true;
			}
		}
		
		//returning false, couldnt find the customer in the list
		return false;
	}
	
	/**
	@notice Fetch bank details for given bank address
	@param bankAddress : address
	@return Bank Struct
	 */
	function getBankDetails ( address bankAddress ) public view returns( Bank memory ) {
	    
	    //checking if bank is available in the list or not
	    for ( uint i = 0; i < bankList.length; i++ ) {
	        
	        if ( bankList[i].ethAddress == bankAddress ) {
	            
	            //bank is available in the list so returning its structure
	            return bankList[i];
	        }
	    }
    }
	

	/**
	@notice Add bank details to the contract if not already exists
	@param bankName : String
	@param bankAddress : address
	@param regNumber : String
	@return UNIT
	 */
	function addBank ( string memory bankName, address bankAddress, string memory regNumber ) public payable returns( uint ) {

	    //checking if the the request made by the admin or not
	    if ( contractOwner == msg.sender ) {
	        
	        for ( uint i = 0; i < bankList.length; i++ ) {
	            
	            //checking if the bank is available in the list or not
	            if ( bankList[i].ethAddress == bankAddress ) {
	                
	                //since bank is already registered rejecting the request by returning 0
	                return 0;
	            }
	        }
	        //since request made by the admin, increasing the bank list by 1 to add the new bank details
	        bankList.length++;
	        
	        //adding new bank details to the list
	        bankList[bankList.length-1]= Bank(bankName,bankAddress,0,0,regNumber);
	        
	        //returning 1 as successfull addition of bank to the list
	        return 1;
	    }
	    
	    //rejecting the request by returning 0
	    return 0;
	}
	
	/**
	@notice Remove bank from the contract 
	@param bankAddress : address
	@return UNIT
	*/
	function removeBank ( address bankAddress ) public payable returns( uint ) {
	    
	    //checking if the request made by the admin or not
	    if ( contractOwner == msg.sender ) {
	        
	        for ( uint i = 0; i < bankList.length; i++ ) {
	            
	            //checking if the bank is available in the list or not
	            if ( bankList[i].ethAddress == bankAddress ) {
	                
	                if ( bankList.length >= 2 && i != (bankList.length-1)) {
	                    
	                    //shifting of banks to left by one postion to remove the bankList
	                    for ( uint j = i+1; j < bankList.length; j++ )
	                    bankList[j-1]=bankList[j];
	                }
	                //decreasing the length of the list by 1
	                bankList.length--;
	                
	                //returning 1 as successfull removal of bank
	                return 1;
	            }
	        }
	    }
	    
	    //rejecting the request/ if bank is not found in the list returns 0
	    return 0;
	}

}