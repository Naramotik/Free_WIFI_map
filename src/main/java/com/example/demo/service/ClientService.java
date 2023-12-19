package com.example.demo.service;

import com.example.demo.model.Client;
import com.example.demo.repository.ClientRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ClientService {
    @Autowired
    private ClientRepository clientRepository;

    public Client findClientByEmail(String email){
        return clientRepository.findByEmail(email);
    }

    public Client save(Client client){
        client.setDisplayName(client.getEmail());
        client.setRole("USER");
        return clientRepository.save(client);
    }

    public Client changeName(String name, String email){
        Client client = clientRepository.findByEmail(email);
        client.setDisplayName(name);
        return clientRepository.save(client);
    }
}
