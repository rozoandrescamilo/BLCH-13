// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract DoTrackValidator {

    struct MetamaskWallet {
        address walletAddress;
        string privateKey;
        string publicKey;
    }

    MetamaskWallet[] public metamaskWallets;

    function createMetamaskWallet(address _walletAddress) public returns (MetamaskWallet memory) {
        require(_walletAddress != address(0), "Invalid Ethereum address");

        bytes32 privateKey = keccak256(abi.encodePacked(block.timestamp, msg.sender, metamaskWallets.length));
        bytes32 publicKey = keccak256(abi.encodePacked(privateKey));

        MetamaskWallet memory newWallet = MetamaskWallet({
            walletAddress: _walletAddress,
            privateKey: bytes32.ToString(privateKey),
            publicKey: bytes32.ToString(publicKey)
        });

        metamaskWallets.push(newWallet);

        return newWallet;
    }

    function getMetamaskWallets() public view returns (MetamaskWallet[] memory) {
        return metamaskWallets;
    }

    function saveMetamaskWalletsToFile(string memory _filePath) public {
        require(metamaskWallets.length > 0, "No Metamask wallets created");

        string memory walletsJson = abi.encodePacked("[", "\n");

        for (uint i = 0; i < metamaskWallets.length; i++) {
            MetamaskWallet memory wallet = metamaskWallets[i];
            string memory walletJson = abi.encodePacked(
                "{",
                "\"walletAddress\": \"", toAscii.String(wallet.walletAddress), "\", ",
                "\"privateKey\": \"", wallet.privateKey, "\", ",
                "\"publicKey\": \"", wallet.publicKey, "\"",
                "}"
            );

            walletsJson = abi.encodePacked(walletsJson, walletJson);

            if (i < metamaskWallets.length - 1) {
                walletsJson = abi.encodePacked(walletsJson, ",", "\n");
            }
        }

        walletsJson = abi.encodePacked(walletsJson, "\n", "]");

        bytes memory walletsBytes = bytes(walletsJson);

        write.File(_filePath, walletsBytes);
    }


    struct Step {
        Status status; 
        string metadata; 
    }


    enum Status {
        TO_BE_CONFIRMED, 
        APPROVED_P1, 
        TO_BE_CONFIRMED_P2, 
        APPROVED_P2, 
        TO_BE_CONFIRMED_P3, 
        APPROVED_P3,
        BOOKING_REQUEST 
    } 


    event RegisteredStep(
        uint256 POID, // ID del producto
        uint256 poType, // Tipo de orden: Entrega total, 2 parciales o 3 parciales
        Status status, // Estado del paso
        string metadata, // Metadatos adicionales
        address author // Dirección del autor
    );


    mapping(uint256 => Step[]) public ParameterValidator;

    function RegisterPO(address userWallet, uint256 POID) public returns (bool success) {
        require(userWallet == msg.sender, "To be able to interact with your Purchase Order you must use your registered wallet address");
        require(ParameterValidator[POID].length == 0, "This product already exists");
        ParameterValidator[POID].push(Step(Status.TO_BE_CONFIRMED, ""));        
        return success;

    }

    mapping(address => bool) allowedWallets;

    constructor() {
        allowedWallets[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true; 
        allowedWallets[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = true; 
        allowedWallets[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = true; 
    }


    function RegisterStep(address userWallet, uint256 POID, string calldata metadata, uint256 poType) public returns (bool success) {
        require(allowedWallets[userWallet] && userWallet == msg.sender, "To be able to interact with your Purchase Order you must use your registered wallet address");
        require(ParameterValidator[POID].length > 0, "This Purchase Order doesn't exist");
        require(poType == 1 || poType == 2 || poType == 3, "Invalid PO type");

        Step[] memory stepsArray = ParameterValidator[POID];

        uint256 currentStatus = uint256(stepsArray[stepsArray.length - 1].status) + 1;

        if (currentStatus > uint256(Status.BOOKING_REQUEST)) {
            revert("The Purchase Order has no more steps");
        }

        if (poType == 1 && currentStatus > 2) {
            revert("The maximum status for poType 1 is 2 BOOKING REQUEST");
        }

        if (poType == 2 && currentStatus > 4) {
            revert("The maximum status for poType 2 is 4 BOOKING REQUEST");
        }

        if (poType == 3 && currentStatus > 6) {
            revert("The maximum status for poType 3 is 6 BOOKING REQUEST");
        }

        Step memory step = Step(Status(currentStatus), metadata);
        ParameterValidator[POID].push(step);

        emit RegisteredStep(POID, poType, Status(currentStatus), metadata, msg.sender);
        success = true;
    }

}
