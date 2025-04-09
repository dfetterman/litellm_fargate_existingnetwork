# LiteLLM AWS Architecture Diagrams

## High-Level Architecture Diagram

```mermaid
graph TD
    User[User/Client] -->|VPN Connection| VPN[AWS Client VPN]
    VPN -->|Secure Access| ALB[Internal Application Load Balancer]
    ALB -->|Routes Traffic| Fargate[AWS Fargate/ECS]
    Fargate -->|Reads/Writes| DB[Aurora PostgreSQL]
    Fargate -->|API Calls| LLMs[LLM Providers]
    
    subgraph AWS VPC
        subgraph Private Subnet
            Fargate
            DB
        end
        ALB
        VPN
    end
    
    subgraph External
        User
        LLMs
    end
    
    classDef aws fill:#FF9900,stroke:#232F3E,color:white;
    classDef external fill:#1EC9E8,stroke:#232F3E,color:white;
    classDef vpc fill:#7AA116,stroke:#232F3E,color:white;
    classDef subnet fill:#5A9C47,stroke:#232F3E,color:white;
    
    class VPN,ALB,Fargate,DB aws;
    class User,LLMs external;
    class AWS vpc;
    class Private subnet;
```

## Component Diagram

```mermaid
flowchart LR
    User[User/Client] -->|OpenVPN| VPN[AWS Client VPN]
    VPN -->|TLS| ALB[Internal ALB]
    ALB -->|HTTP| Fargate[Fargate Service]
    
    subgraph Fargate Service
        Container[LiteLLM Container]
    end
    
    Container -->|SQL| DB[(Aurora PostgreSQL)]
    Container -->|HTTPS| Bedrock[AWS Bedrock]
    Container -->|HTTPS| OpenAI[OpenAI API]
    Container -->|HTTPS| Anthropic[Anthropic API]
    
    classDef aws fill:#FF9900,stroke:#232F3E,color:white;
    classDef external fill:#1EC9E8,stroke:#232F3E,color:white;
    
    class VPN,ALB,Fargate,Container,DB,Bedrock aws;
    class User,OpenAI,Anthropic external;
```

## Network Flow Diagram

```mermaid
sequenceDiagram
    participant User as User/Client
    participant VPN as AWS Client VPN
    participant ALB as Internal ALB
    participant Fargate as LiteLLM Container
    participant DB as Aurora PostgreSQL
    participant LLM as LLM Provider API
    
    User->>VPN: Connect via OpenVPN
    VPN->>User: Establish encrypted tunnel
    User->>ALB: HTTP Request
    ALB->>Fargate: Forward Request
    Fargate->>DB: Query API keys/config
    DB->>Fargate: Return data
    Fargate->>LLM: Forward LLM API request
    LLM->>Fargate: Return LLM response
    Fargate->>ALB: Return API response
    ALB->>User: Deliver response
```

## Deployment Architecture

```mermaid
graph TD
    subgraph "AWS Cloud"
        subgraph "VPC"
            subgraph "Availability Zone 1"
                subgraph "Private Subnet 1"
                    Fargate1[Fargate Task]
                    DB1[Aurora Instance]
                end
            end
            
            subgraph "Availability Zone 2"
                subgraph "Private Subnet 2"
                    Fargate2[Fargate Task]
                    DB2[Aurora Instance]
                end
            end
            
            ALB[Internal ALB]
            VPN[Client VPN Endpoint]
            
            ALB --> Fargate1
            ALB --> Fargate2
            Fargate1 --> DB1
            Fargate2 --> DB2
            DB1 <--> DB2
        end
    end
    
    User[User/Client] --> VPN
    VPN --> ALB
    
    classDef az fill:#FF9900,stroke:#232F3E,color:white;
    classDef subnet fill:#7AA116,stroke:#232F3E,color:white;
    classDef resource fill:#1EC9E8,stroke:#232F3E,color:white;
    
    class "Availability Zone 1","Availability Zone 2" az;
    class "Private Subnet 1","Private Subnet 2" subnet;
    class Fargate1,Fargate2,DB1,DB2,ALB,VPN resource;
```

Note: These diagrams are in Mermaid format and can be rendered as images using Mermaid.js or other Mermaid rendering tools. For the README.md, you'll need to create actual PNG/SVG images from these diagrams.
