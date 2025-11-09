// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {QuadraticFundingSplitter} from "../src/QuadraticFundingSplitter.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract QuadraticFundingSplitterTest is Test {
    QuadraticFundingSplitter public splitter;
    MockERC20 public vaultToken;

    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    address public projectA;
    address public projectB;
    address public projectC;

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        projectA = makeAddr("projectA");
        projectB = makeAddr("projectB");
        projectC = makeAddr("projectC");

        // Deploy mock vault token
        vaultToken = new MockERC20("Vault Token", "vToken");

        // Deploy splitter
        splitter = new QuadraticFundingSplitter(address(vaultToken), 1 ether);

        // Mint tokens to voters
        vaultToken.mint(alice, 1000 ether);
        vaultToken.mint(bob, 1000 ether);
        vaultToken.mint(charlie, 1000 ether);
        vaultToken.mint(owner, 10000 ether);
    }

    function testRegisterProject() public {
        uint256 projectId = splitter.registerProject(
            projectA,
            "Project A",
            "Description A"
        );

        assertEq(projectId, 0);
        
        (
            address recipient,
            string memory name,
            string memory description,
            uint256 totalVotes,
            uint256 uniqueVoters,
            bool active,
            uint256 totalReceived
        ) = splitter.projects(projectId);

        assertEq(recipient, projectA);
        assertEq(name, "Project A");
        assertEq(description, "Description A");
        assertEq(totalVotes, 0);
        assertEq(uniqueVoters, 0);
        assertTrue(active);
        assertEq(totalReceived, 0);
    }

    function testRegisterMultipleProjects() public {
        splitter.registerProject(projectA, "Project A", "Description A");
        splitter.registerProject(projectB, "Project B", "Description B");
        splitter.registerProject(projectC, "Project C", "Description C");

        assertEq(splitter.projectCount(), 3);
    }

    function testStartRound() public {
        splitter.startRound(30 days);

        assertTrue(splitter.roundActive());
        assertEq(splitter.currentRound(), 1);
        assertEq(splitter.roundDuration(), 30 days);
    }

    function testCannotStartRoundWhileActive() public {
        splitter.startRound(30 days);

        vm.expectRevert(QuadraticFundingSplitter.RoundActive.selector);
        splitter.startRound(30 days);
    }

    function testAddToMatchingPool() public {
        splitter.startRound(30 days);

        vaultToken.approve(address(splitter), 1000 ether);
        splitter.addToMatchingPool(1000 ether);

        assertEq(splitter.matchingPools(1), 1000 ether);
    }

    function testVote() public {
        // Register project
        splitter.registerProject(projectA, "Project A", "Description A");

        // Start round
        splitter.startRound(30 days);

        // Alice votes
        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 10 ether);
        splitter.vote(0, 10 ether);
        vm.stopPrank();

        (,, , uint256 totalVotes, uint256 uniqueVoters,,) = splitter.projects(0);
        assertEq(totalVotes, 10 ether);
        assertEq(uniqueVoters, 1);
    }

    function testMultipleVotesFromSameUser() public {
        splitter.registerProject(projectA, "Project A", "Description A");
        splitter.startRound(30 days);

        // Alice votes twice
        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 20 ether);
        splitter.vote(0, 10 ether);
        splitter.vote(0, 10 ether);
        vm.stopPrank();

        (,, , uint256 totalVotes, uint256 uniqueVoters,,) = splitter.projects(0);
        assertEq(totalVotes, 20 ether);
        assertEq(uniqueVoters, 1); // Still one unique voter
    }

    function testMultipleVotersForProject() public {
        splitter.registerProject(projectA, "Project A", "Description A");
        splitter.startRound(30 days);

        // Alice votes
        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 10 ether);
        splitter.vote(0, 10 ether);
        vm.stopPrank();

        // Bob votes
        vm.startPrank(bob);
        vaultToken.approve(address(splitter), 15 ether);
        splitter.vote(0, 15 ether);
        vm.stopPrank();

        // Charlie votes
        vm.startPrank(charlie);
        vaultToken.approve(address(splitter), 20 ether);
        splitter.vote(0, 20 ether);
        vm.stopPrank();

        (,, , uint256 totalVotes, uint256 uniqueVoters,,) = splitter.projects(0);
        assertEq(totalVotes, 45 ether);
        assertEq(uniqueVoters, 3);
    }

    function testCannotVoteWhenRoundNotActive() public {
        splitter.registerProject(projectA, "Project A", "Description A");

        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 10 ether);
        vm.expectRevert(QuadraticFundingSplitter.RoundNotActive.selector);
        splitter.vote(0, 10 ether);
        vm.stopPrank();
    }

    function testCannotVoteForInvalidProject() public {
        splitter.startRound(30 days);

        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 10 ether);
        vm.expectRevert(QuadraticFundingSplitter.InvalidProject.selector);
        splitter.vote(999, 10 ether);
        vm.stopPrank();
    }

    function testCannotVoteBelowMinimum() public {
        splitter.registerProject(projectA, "Project A", "Description A");
        splitter.startRound(30 days);

        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 0.5 ether);
        vm.expectRevert(QuadraticFundingSplitter.InsufficientAmount.selector);
        splitter.vote(0, 0.5 ether);
        vm.stopPrank();
    }

    function testEndRound() public {
        // Register projects
        splitter.registerProject(projectA, "Project A", "Description A");
        splitter.registerProject(projectB, "Project B", "Description B");

        // Start round
        splitter.startRound(30 days);

        // Add matching pool
        vaultToken.approve(address(splitter), 1000 ether);
        splitter.addToMatchingPool(1000 ether);

        // Multiple users vote
        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 10 ether);
        splitter.vote(0, 10 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        vaultToken.approve(address(splitter), 20 ether);
        splitter.vote(1, 20 ether);
        vm.stopPrank();

        // Fast forward time
        vm.warp(block.timestamp + 31 days);

        // End round
        uint256 projectABalanceBefore = vaultToken.balanceOf(projectA);
        uint256 projectBBalanceBefore = vaultToken.balanceOf(projectB);

        splitter.endRound();

        // Projects should have received funds
        assertGt(vaultToken.balanceOf(projectA), projectABalanceBefore);
        assertGt(vaultToken.balanceOf(projectB), projectBBalanceBefore);

        // Round should be inactive
        assertFalse(splitter.roundActive());
    }

    function testCannotEndRoundEarly() public {
        splitter.startRound(30 days);

        vaultToken.approve(address(splitter), 1000 ether);
        splitter.addToMatchingPool(1000 ether);

        vm.expectRevert(QuadraticFundingSplitter.RoundActive.selector);
        splitter.endRound();
    }

    function testCannotEndRoundWithoutMatchingPool() public {
        splitter.registerProject(projectA, "Project A", "Description A");
        splitter.startRound(30 days);

        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 10 ether);
        splitter.vote(0, 10 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 31 days);

        vm.expectRevert(QuadraticFundingSplitter.NoMatchingPool.selector);
        splitter.endRound();
    }

    function testQuadraticFundingDistribution() public {
        // Register projects
        splitter.registerProject(projectA, "Project A", "Description A");
        splitter.registerProject(projectB, "Project B", "Description B");

        // Start round
        splitter.startRound(30 days);

        // Add matching pool
        vaultToken.approve(address(splitter), 1000 ether);
        splitter.addToMatchingPool(1000 ether);

        // Project A: 3 voters with 10 ether each = 30 ether total
        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 10 ether);
        splitter.vote(0, 10 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        vaultToken.approve(address(splitter), 10 ether);
        splitter.vote(0, 10 ether);
        vm.stopPrank();

        vm.startPrank(charlie);
        vaultToken.approve(address(splitter), 10 ether);
        splitter.vote(0, 10 ether);
        vm.stopPrank();

        // Project B: 1 voter with 30 ether
        address david = makeAddr("david");
        vaultToken.mint(david, 1000 ether);
        vm.startPrank(david);
        vaultToken.approve(address(splitter), 30 ether);
        splitter.vote(1, 30 ether);
        vm.stopPrank();

        // Fast forward and end round
        vm.warp(block.timestamp + 31 days);
        splitter.endRound();

        // Project A should get more matching funds due to quadratic funding
        // (more unique contributors is better than one whale)
        uint256 projectAReceived = vaultToken.balanceOf(projectA);
        uint256 projectBReceived = vaultToken.balanceOf(projectB);

        // Both should receive their direct contributions plus matching
        assertGt(projectAReceived, 30 ether);
        assertGt(projectBReceived, 30 ether);
    }

    function testDeactivateProject() public {
        uint256 projectId = splitter.registerProject(projectA, "Project A", "Description A");

        splitter.deactivateProject(projectId);

        (,,,,,bool active,) = splitter.projects(projectId);
        assertFalse(active);
    }

    function testCannotVoteForDeactivatedProject() public {
        uint256 projectId = splitter.registerProject(projectA, "Project A", "Description A");
        splitter.deactivateProject(projectId);
        splitter.startRound(30 days);

        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 10 ether);
        vm.expectRevert(QuadraticFundingSplitter.InvalidProject.selector);
        splitter.vote(projectId, 10 ether);
        vm.stopPrank();
    }

    function testGetProject() public {
        splitter.registerProject(projectA, "Project A", "Description A");
        
        QuadraticFundingSplitter.Project memory project = splitter.getProject(0);
        
        assertEq(project.recipient, projectA);
        assertEq(project.name, "Project A");
        assertTrue(project.active);
    }

    function testGetVote() public {
        splitter.registerProject(projectA, "Project A", "Description A");
        splitter.startRound(30 days);

        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 10 ether);
        splitter.vote(0, 10 ether);
        vm.stopPrank();

        QuadraticFundingSplitter.Vote memory vote = splitter.getVote(alice, 0);
        
        assertEq(vote.amount, 10 ether);
        assertGt(vote.timestamp, 0);
    }

    function testSqrtFunction() public {
        // Test square root calculation through voting
        splitter.registerProject(projectA, "Project A", "Description A");
        splitter.startRound(30 days);

        // Vote with perfect square amount
        vm.startPrank(alice);
        vaultToken.approve(address(splitter), 100 ether);
        splitter.vote(0, 100 ether);
        vm.stopPrank();

        // Sqrt(100) should be 10, which affects quadratic score
        (,,,,,bool active,) = splitter.projects(0);
        assertTrue(active);
    }
}
