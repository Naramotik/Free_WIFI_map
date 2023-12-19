package com.example.demo.controller;

import com.example.demo.model.Client;
import com.example.demo.service.ClientService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin(origins = "http://localhost:3000")
@RequestMapping("/client")
public class ClientController {

    @Autowired
    private ClientService clientService;

    @PostMapping("/register")
    public Client register(@RequestBody Client client){
        return clientService.save(client);
    }

    @PutMapping("/change-name/{name}/{email}")
    public Client changeName(@PathVariable("name") String name,
                             @PathVariable("email") String email){
        return clientService.changeName(name, email);
    }

    @GetMapping("/{email}")
    public Client getUserInfo(@PathVariable String email){
        return clientService.findClientByEmail(email);
    }
}
