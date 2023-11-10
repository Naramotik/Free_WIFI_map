package com.example.demo.service;

import com.example.demo.dto.MarkToPost;
import com.example.demo.model.Client;
import com.example.demo.model.Mark;
import com.example.demo.repository.MarkRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MarkService {
    @Autowired
    private MarkRepository markRepository;
    @Autowired
    private ClientService clientService;


    public Mark save(MarkToPost markToPost){
        Mark mark = markToPost.getMark();
        Client client = clientService.findClientByEmail(markToPost.getEmail());
        mark.setClient(client);
        return markRepository.save(mark);
    }

    public List<Mark> findAll(){
        return markRepository.findAll();
    }
}
