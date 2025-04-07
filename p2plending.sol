// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract P2PLendingSystem {
    struct LoanRequest {
        uint id;
        address payable borrower;
        uint amount;
        uint interestRate; // in percentage (e.g., 5 means 5%)
        uint duration; // in seconds
        bool funded;
        address payable lender;
        bool repaid;
    }

    uint public loanCounter;
    mapping(uint => LoanRequest) public loans;

    event LoanRequested(uint id, address borrower, uint amount, uint interestRate, uint duration);
    event LoanFunded(uint id, address lender);
    event LoanRepaid(uint id);

    function requestLoan(uint _amount, uint _interestRate, uint _duration) external {
        require(_amount > 0, "Amount must be greater than zero.");
        require(_interestRate > 0, "Interest rate must be greater than zero.");
        require(_duration > 0, "Duration must be greater than zero.");

        loanCounter++;
        loans[loanCounter] = LoanRequest({
            id: loanCounter,
            borrower: payable(msg.sender),
            amount: _amount,
            interestRate: _interestRate,
            duration: _duration,
            funded: false,
            lender: payable(address(0)),
            repaid: false
        });

        emit LoanRequested(loanCounter, msg.sender, _amount, _interestRate, _duration);
    }

    function fundLoan(uint _loanId) external payable {
        LoanRequest storage loan = loans[_loanId];
        require(!loan.funded, "Loan already funded.");
        require(msg.value == loan.amount, "Incorrect amount sent.");

        loan.lender = payable(msg.sender);
        loan.funded = true;
        loan.borrower.transfer(loan.amount);

        emit LoanFunded(_loanId, msg.sender);
    }

    function repayLoan(uint _loanId) external payable {
        LoanRequest storage loan = loans[_loanId];
        require(loan.funded, "Loan not funded yet.");
        require(!loan.repaid, "Loan already repaid.");
        require(msg.sender == loan.borrower, "Only borrower can repay.");

        uint interest = (loan.amount * loan.interestRate) / 100;
        uint totalRepayment = loan.amount + interest;

        require(msg.value == totalRepayment, "Incorrect repayment amount.");

        loan.repaid = true;
        loan.lender.transfer(msg.value);

        emit LoanRepaid(_loanId);
    }

    function getLoanDetails(uint _loanId) external view returns (
        address borrower,
        uint amount,
        uint interestRate,
        uint duration,
        bool funded,
        address lender,
        bool repaid
    ) {
        LoanRequest storage loan = loans[_loanId];
        return (
            loan.borrower,
            loan.amount,
            loan.interestRate,
            loan.duration,
            loan.funded,
            loan.lender,
            loan.repaid
        );
    }
}